# frozen_string_literal: true

require "rails_helper"

RSpec.describe External::ExchangeRatesFetcher do
  # Test env uses :null_store — swap in a real MemoryStore so caching tests work.
  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(memory_cache)
  end

  subject(:fetcher) { described_class.new }

  it "trae oficial y blue de dolarapi" do
    stub_request(:get, "https://dolarapi.com/v1/dolares")
      .to_return(
        status: 200,
        body: [
          { "casa" => "oficial", "compra" => 1045, "venta" => 1085, "fechaActualizacion" => "2026-05-22T10:00:00Z" },
          { "casa" => "blue",    "compra" => 1200, "venta" => 1250, "fechaActualizacion" => "2026-05-22T10:00:00Z" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    rates = fetcher.call
    expect(rates[:oficial][:compra]).to eq(1045)
    expect(rates[:oficial][:venta]).to eq(1085)
    expect(rates[:blue][:compra]).to eq(1200)
    expect(rates[:stale]).to eq(false)
  end

  it "cachea durante 1 hora (segundo call no hace HTTP)" do
    stub_request(:get, "https://dolarapi.com/v1/dolares")
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

    2.times { fetcher.call }
    expect(WebMock).to have_requested(:get, "https://dolarapi.com/v1/dolares").once
  end

  it "devuelve stale si la API falla y hay last_known" do
    Rails.cache.write("fx:dolarapi:last_known", { oficial: { compra: 999, venta: 1000 }, blue: {} })
    stub_request(:get, "https://dolarapi.com/v1/dolares").to_return(status: 500)

    rates = fetcher.call
    expect(rates[:oficial][:compra]).to eq(999)
    expect(rates[:stale]).to eq(true)
  end

  it "devuelve vacío con stale si no hay nada" do
    stub_request(:get, "https://dolarapi.com/v1/dolares").to_timeout

    rates = fetcher.call
    expect(rates).to eq(stale: true, oficial: {}, blue: {})
  end
end
