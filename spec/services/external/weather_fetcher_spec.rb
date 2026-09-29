# frozen_string_literal: true

require "rails_helper"

RSpec.describe External::WeatherFetcher do
  # Test env uses :null_store — swap in a real MemoryStore so caching tests work.
  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(memory_cache)
  end

  def build_forecast_payload(days: 5)
    list = []
    base = Time.utc(2026, 5, 20, 0, 0, 0)
    days.times do |d|
      8.times do |h|
        dt = base + d.days + (h * 3).hours
        list << {
          "dt_txt" => dt.strftime("%Y-%m-%d %H:%M:%S"),
          "main" => {
            "temp"     => 20.0 + d + h,
            "temp_max" => 28.0 + d,
            "temp_min" => 15.0 + d
          },
          "weather" => [ { "icon" => "01d", "description" => "cielo despejado" } ]
        }
      end
    end
    { "list" => list }
  end

  subject(:fetcher) { described_class.new(lat: -34.61, lng: -58.37) }

  it "devuelve nil si lat es blank" do
    result = described_class.new(lat: nil, lng: -58.37).call
    expect(result).to be_nil
  end

  it "devuelve nil si lng es blank" do
    result = described_class.new(lat: -34.61, lng: nil).call
    expect(result).to be_nil
  end

  it "trae pronostico de 5 dias agrupado por fecha" do
    stub_request(:get, /api\.openweathermap\.org/)
      .to_return(
        status: 200,
        body: build_forecast_payload(days: 5).to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = fetcher.call

    expect(result[:stale]).to eq(false)
    expect(result[:days].size).to be_between(1, 5)
    expect(result[:days].first).to include(:date, :max, :min, :icon, :description)
  end

  it "cachea por lat/lng redondeados a 2 decimales (dos coords cercanas = 1 sola peticion)" do
    stub_request(:get, /api\.openweathermap\.org/)
      .to_return(
        status: 200,
        body: build_forecast_payload(days: 2).to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # coords que redondean al mismo valor (-34.61, -58.37)
    described_class.new(lat: -34.6100001, lng: -58.3700001).call
    described_class.new(lat: -34.6099999, lng: -58.3699999).call

    expect(WebMock).to have_requested(:get, /api\.openweathermap\.org/).once
  end

  it "devuelve stale si la API falla y hay last_known" do
    saved = { current: { date: "2026-05-20" }, days: [ { date: "2026-05-20", max: 28.0, min: 15.0, icon: "01d", description: "soleado" } ], stale: false }
    memory_cache.write("weather:-34.61:-58.37:last_known", saved)

    stub_request(:get, /api\.openweathermap\.org/).to_return(status: 500)

    result = fetcher.call
    expect(result[:stale]).to eq(true)
    expect(result[:days]).not_to be_empty
  end

  it "no cachea los fallos (reintenta en la siguiente llamada)" do
    # primera llamada falla
    stub_request(:get, /api\.openweathermap\.org/).to_return(status: 500)
    first = fetcher.call
    expect(first[:stale]).to eq(true)

    # la API se recupera — la siguiente llamada DEBE reintentar y traer datos frescos
    stub_request(:get, /api\.openweathermap\.org/)
      .to_return(
        status: 200,
        body: build_forecast_payload(days: 1).to_json,
        headers: { "Content-Type" => "application/json" }
      )

    second = fetcher.call
    expect(second[:stale]).to eq(false)
  end
end
