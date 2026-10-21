# frozen_string_literal: true

require "net/http"
require "json"

module External
  class ExchangeRatesFetcher
    URL            = URI("https://dolarapi.com/v1/dolares").freeze
    CACHE_KEY      = "fx:dolarapi".freeze
    LAST_KNOWN_KEY = "fx:dolarapi:last_known".freeze
    # Tras un fallo, durante RETRY_AFTER se responde el último valor conocido
    # sin volver a pegarle a la API: la cotización se pide en cada página del
    # constructor cuando hay obras en USD (KPIs del topbar), y con dolarapi
    # caído cada request esperaba el timeout. El fallo NO se guarda en
    # CACHE_KEY: pasada la pausa se reintenta.
    DOWN_KEY       = "fx:dolarapi:down".freeze
    RETRY_AFTER    = 2.minutes
    TIMEOUT_S      = 3

    def call
      return stale_fallback if Rails.cache.read(DOWN_KEY)

      Rails.cache.fetch(CACHE_KEY, expires_in: 1.hour) { fetch_and_remember }
    rescue StandardError => e
      Rails.logger.warn("ExchangeRatesFetcher failed: #{e.message}")
      Rails.cache.write(DOWN_KEY, true, expires_in: RETRY_AFTER)
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
