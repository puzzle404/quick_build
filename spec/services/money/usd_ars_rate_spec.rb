# frozen_string_literal: true

require "rails_helper"

RSpec.describe Money::UsdArsRate do
  before { Current.reset }
  after { Current.reset }

  def stub_rates(hash)
    allow_any_instance_of(External::ExchangeRatesFetcher).to receive(:call).and_return(hash)
  end

  it "usa el dólar oficial venta" do
    stub_rates(oficial: { compra: 1045, venta: 1085 }, blue: { compra: 1200, venta: 1250 }, stale: false)
    expect(described_class.current).to eq(BigDecimal("1085"))
  end

  it "cae a la compra si no hay venta" do
    stub_rates(oficial: { compra: 1045 }, blue: {}, stale: true)
    expect(described_class.current).to eq(BigDecimal("1045"))
  end

  it "es nil sin cotización (dolarapi caído y sin último valor conocido)" do
    stub_rates(oficial: {}, blue: {}, stale: true)
    expect(described_class.current).to be_nil
  end

  it "se pide una sola vez por request" do
    fetcher = instance_double(External::ExchangeRatesFetcher, call: { oficial: { venta: 1085 } })
    allow(External::ExchangeRatesFetcher).to receive(:new).and_return(fetcher)

    2.times { described_class.current }

    expect(fetcher).to have_received(:call).once
  end
end
