# frozen_string_literal: true

require "net/http"
require "json"

module External
  class ExchangeRatesFetcher
    URL           = URI("https://dolarapi.com/v1/dolares").freeze
    CACHE_KEY     = "fx:dolarapi".freeze
    LAST_KNOWN_KEY = "fx:dolarapi:last_known".freeze
    TIMEOUT_S     = 5

    def call
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) do
        result = fetch_remote
        Rails.cache.write(LAST_KNOWN_KEY, result) if result[:stale] == false
        result
      end
    end

    private

    def fetch_remote
      response = Net::HTTP.start(URL.host, URL.port, use_ssl: true,
                                  open_timeout: TIMEOUT_S, read_timeout: TIMEOUT_S) do |http|
        http.get(URL.request_uri)
      end

      raise "HTTP #{response.code}" unless response.code.to_i == 200

      parse(JSON.parse(response.body))
    rescue StandardError => e
      Rails.logger.warn("ExchangeRatesFetcher failed: #{e.message}")
      last = Rails.cache.read(LAST_KNOWN_KEY) || { oficial: {}, blue: {} }
      last.merge(stale: true)
    end

    def parse(payload)
      oficial = payload.find { |r| r["casa"] == "oficial" } || {}
      blue    = payload.find { |r| r["casa"] == "blue" }    || {}

      {
        oficial: extract(oficial),
        blue:    extract(blue),
        stale:   false
      }
    end

    def extract(row)
      return {} if row.empty?

      {
        compra: row["compra"],
        venta:  row["venta"],
        fecha:  row["fechaActualizacion"]
      }
    end
  end
end
