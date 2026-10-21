class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # Cotización del dólar memoizada por request (Money::UsdArsRate).
  attribute :usd_ars_rate, :usd_ars_rate_loaded

  delegate :user, to: :session, allow_nil: true
end
