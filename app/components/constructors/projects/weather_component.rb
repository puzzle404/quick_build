# frozen_string_literal: true

# Widget de clima de 5 días para la página de detalle de proyecto.
# Acepta el hash producido por External::WeatherFetcher#call.
# No renderiza nada si no hay coordenadas (forecast nil) o si no hay días.
class Constructors::Projects::WeatherComponent < ViewComponent::Base
  def initialize(forecast:, project:)
    @forecast = forecast
    @project  = project
  end

  def render?
    @forecast.present? && @forecast[:days].present? && @forecast[:days].any?
  end

  def stale?
    @forecast[:stale] == true
  end

  def days
    @forecast[:days] || []
  end

  def location_title
    @project.location.presence || "la obra"
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
