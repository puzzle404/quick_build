# frozen_string_literal: true

require "net/http"
require "json"

module External
  class WeatherFetcher
    BASE_URL = "https://api.openweathermap.org/data/2.5/forecast".freeze
    TIMEOUT_S = 5

    def initialize(lat:, lng:)
      @lat = lat
      @lng = lng
    end

    def call
      return nil if @lat.blank? || @lng.blank?

      lat2 = @lat.to_f.round(2)
      lng2 = @lng.to_f.round(2)

      cache_key      = "weather:#{lat2}:#{lng2}"
      last_known_key = "weather:#{lat2}:#{lng2}:last_known"

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        result = fetch_remote(lat2, lng2)
        Rails.cache.write(last_known_key, result)
        result
      end
    rescue StandardError => e
      Rails.logger.warn("WeatherFetcher failed: #{e.message}")
      stale_fallback(lat2, lng2)
    end

    private

    # Raises on any failure so Rails.cache.fetch does NOT store a bad result.
    def fetch_remote(lat2, lng2)
      uri = URI(BASE_URL)
      uri.query = URI.encode_www_form(
        lat: lat2,
        lon: lng2,
        units: "metric",
        lang: "es",
        appid: ENV.fetch("OPENWEATHER_API_KEY", "")
      )

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                  open_timeout: TIMEOUT_S, read_timeout: TIMEOUT_S) do |http|
        http.get(uri.request_uri)
      end

      raise "HTTP #{response.code}" unless response.code.to_i == 200

      parse(JSON.parse(response.body))
    end

    def stale_fallback(lat2, lng2)
      last_known_key = "weather:#{lat2}:#{lng2}:last_known"
      last = Rails.cache.read(last_known_key)
      return last.merge(stale: true) if last

      { current: {}, days: [], stale: true }
    end

    def parse(payload)
      list = payload["list"] || []

      days = list
        .group_by { |slot| slot["dt_txt"]&.split(" ")&.first }
        .first(5)
        .map do |date, slots|
          max = slots.map { |s| s.dig("main", "temp_max") }.compact.max
          min = slots.map { |s| s.dig("main", "temp_min") }.compact.min

          midday = slots.find { |s| s["dt_txt"]&.include?("12:00:00") } || slots.first || {}
          icon        = midday.dig("weather", 0, "icon")
          description = midday.dig("weather", 0, "description")

          {
            date: date,
            max: max,
            min: min,
            icon: icon,
            description: description
          }
        end

      first_day = days.first || {}
      { current: first_day, days: days, stale: false }
    end
  end
end
