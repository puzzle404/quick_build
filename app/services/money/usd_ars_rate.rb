# frozen_string_literal: true

module Money
  # Cotización para llevar a pesos los presupuestos cargados en dólares:
  # dólar oficial venta de dolarapi (External::ExchangeRatesFetcher, cacheado
  # 1 h y con último valor conocido si la API falla). Se memoiza por request
  # en Current: un listado con muchas obras pide la cotización una sola vez.
  # nil = no hay cotización; quien convierte apaga la comparación.
  class UsdArsRate
    def self.current
      return Current.usd_ars_rate if Current.usd_ars_rate_loaded

      Current.usd_ars_rate_loaded = true
      Current.usd_ars_rate = fetch
    end

    def self.fetch
      rates = External::ExchangeRatesFetcher.new.call
      value = rates.dig(:oficial, :venta) || rates.dig(:oficial, :compra)
      rate = value.to_s.to_d
      rate.positive? ? rate : nil
    rescue StandardError
      nil
    end
  end
end
