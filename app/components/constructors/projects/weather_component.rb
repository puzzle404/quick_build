# frozen_string_literal: true

# Widget de clima de 5 días para la página de detalle de proyecto.
# Acepta el hash producido por External::WeatherFetcher#call.
# No renderiza nada si no hay coordenadas (forecast nil) o si no hay días.
class Constructors::Projects::WeatherComponent < ViewComponent::Base
  # compact: una sola línea horizontal para barras superiores (igual estilo
  # que ExchangeRatesComponent compact). En compact siempre se renderiza
  # (con placeholder "sin datos" si la API no respondió o falta API key).
  def initialize(forecast:, project:, compact: false, location_override: nil)
    @forecast = forecast
    @project  = project
    @compact  = compact
    @location_override = location_override
  end

  def compact?
    @compact
  end

  def render?
    return true if compact?
    @forecast.present? && @forecast[:days].present? && @forecast[:days].any?
  end

  def has_data?
    @forecast.present? && @forecast[:days].present? && @forecast[:days].any?
  end

  def today
    days.first || {}
  end

  def stale?
    @forecast[:stale] == true
  end

  def days
    @forecast[:days] || []
  end

  def location_title
    @location_override.presence || @project&.location.presence || "la obra"
  end

  def icon_url(icon)
    return nil if icon.blank?
    "https://openweathermap.org/img/wn/#{icon}.png"
  end

  def fmt_temp(value)
    return "—" if value.nil?
    "#{value.round}°"
  end

  def fmt_date(date_str)
    return "—" if date_str.blank?
    Date.parse(date_str).strftime("%d/%m")
  rescue ArgumentError
    date_str
  end
end
