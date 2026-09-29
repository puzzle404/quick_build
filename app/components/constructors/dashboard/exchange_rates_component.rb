# frozen_string_literal: true

# Widget de tipo de cambio USD/ARS — muestra oficial y blue desde dolarapi.com.
# Acepta el hash producido por External::ExchangeRatesFetcher#call.
# Cuando rates es nil (primera carga sin datos) muestra empty-state con badge "desactualizado".
class Constructors::Dashboard::ExchangeRatesComponent < ViewComponent::Base
  include QuickbuildHelper

  DEFAULT_RATES = { oficial: {}, blue: {}, stale: true }.freeze

  # compact: una sola línea horizontal para la barra superior del dashboard.
  def initialize(rates: nil, compact: false)
    @rates = rates&.is_a?(Hash) ? rates : DEFAULT_RATES
    @compact = compact
  end

  def compact?
    @compact
  end

  def stale?
    @rates[:stale] == true
  end

  def oficial
    @rates[:oficial] || {}
  end

  def blue
    @rates[:blue] || {}
  end

  def has_data?
    oficial.any? || blue.any?
  end

  def fmt_rate(value)
    return "—" if value.nil?
    qb_fmt_ars_full(value.to_f)
  end
end
