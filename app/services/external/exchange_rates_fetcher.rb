# frozen_string_literal: true

require "net/http"
require "json"

module External
  class ExchangeRatesFetcher
    URL            = URI("https://dolarapi.com/v1/dolares").freeze
    CACHE_KEY      = "fx:dolarapi".freeze
    LAST_KNOWN_KEY = "fx:dolarapi:last_known".freeze
    TIMEOUT_S      = 5

    def call
      Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) { fetch_and_remember }
    rescue StandardError => e
      Rails.logger.warn("ExchangeRatesFetcher failed: #{e.message}")
      stale_fallback
    end

    private

    # Raises on any failure so Rails.cache.fetch does NOT store a bad result.
    def fetch_and_remember
      result = fetch_remote
      Rails.cache.write(LAST_KNOWN_KEY, result)
      result
    end

    def fetch_remote
      response = Net::HTTP.start(URL.host, URL.port, use_ssl: true,
                                  open_timeout: TIMEOUT_S, read_timeout: TIMEOUT_S) do |http|
        http.get(URL.request_uri)
      end

      raise "HTTP #{response.code}" unless response.code.to_i == 200

      parse(JSON.parse(response.body))
    end

    def stale_fallback
      last = Rails.cache.read(LAST_KNOWN_KEY)
      return last.merge(stale: true) if last

      { stale: true, oficial: {}, blue: {} }
    end

    def parse(payload)
      oficial = payload.find { |r| r["casa"] == "oficial" } || {}
      blue    = payload.find { |r| r["casa"] == "blue" }    || {}

      { oficial: extract(oficial), blue: extract(blue), stale: false }
    end

    def extract(row)
      return {} if row.empty?

      { compra: row["compra"], venta: row["venta"], fecha: row["fechaActualizacion"] }
    end
  end
end
