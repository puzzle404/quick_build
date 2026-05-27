# frozen_string_literal: true

# Default stubs for the external HTTP APIs the app calls while rendering pages
# (dashboard tipo-de-cambio widget → dolarapi; project show clima widget →
# openweather). Without these, any spec that renders the dashboard or a project
# would hit the network and WebMock would raise NetConnectNotAllowedError —
# which descends from Exception, not StandardError, so the services' own
# `rescue StandardError` cannot swallow it.
#
# Individual specs override these by declaring their own `stub_request` inside
# the example (the most recently declared matching stub wins in WebMock).
#
# Scoped to :request and :system specs only — model/service/component specs
# that test these APIs directly declare their own stubs and must not be
# affected by a global default.
module ExternalApiStubs
  def stub_external_apis
    stub_request(:get, "https://dolarapi.com/v1/dolares").to_return(
      status: 200,
      body: [
        { "casa" => "oficial", "compra" => 1045, "venta" => 1085, "fechaActualizacion" => "2026-05-22T10:00:00Z" },
        { "casa" => "blue",    "compra" => 1200, "venta" => 1250, "fechaActualizacion" => "2026-05-22T10:00:00Z" }
      ].to_json,
      headers: { "Content-Type" => "application/json" }
    )

    stub_request(:get, /api\.openweathermap\.org/).to_return(
      status: 200,
      body: { "list" => [] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end
end

RSpec.configure do |config|
  config.include ExternalApiStubs
  config.before(:each, type: :request) { stub_external_apis }
  config.before(:each, type: :system)  { stub_external_apis }
end
