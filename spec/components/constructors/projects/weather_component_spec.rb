# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::WeatherComponent, type: :component do
  let(:project) { build_stubbed(:project, location: "Buenos Aires") }

  let(:one_day_forecast) do
    {
      current: { date: "2026-05-20", max: 28.0, min: 15.0, icon: "01d", description: "cielo despejado" },
      days: [
        { date: "2026-05-20", max: 28.0, min: 15.0, icon: "01d", description: "cielo despejado" }
      ],
      stale: false
    }
  end

  it "no renderiza cuando forecast es nil" do
    render_inline(described_class.new(forecast: nil, project: project))
    expect(page.text).to be_blank
  end

  it "no renderiza cuando days esta vacio" do
    forecast = { current: {}, days: [], stale: false }
    render_inline(described_class.new(forecast: forecast, project: project))
    expect(page.text).to be_blank
  end

  it "renderiza el titulo con la ubicacion del proyecto" do
    render_inline(described_class.new(forecast: one_day_forecast, project: project))
    expect(page).to have_text("Clima en Buenos Aires")
  end

  it "renderiza la temperatura max/min del dia" do
    render_inline(described_class.new(forecast: one_day_forecast, project: project))
    expect(page).to have_text("28°")
    expect(page).to have_text("15°")
  end

  it "renderiza la descripcion del tiempo" do
    render_inline(described_class.new(forecast: one_day_forecast, project: project))
    expect(page).to have_text("cielo despejado")
  end

  it "no muestra badge desactualizado cuando stale es false" do
    render_inline(described_class.new(forecast: one_day_forecast, project: project))
    expect(page).not_to have_text("desactualizado")
  end

  it "muestra badge desactualizado cuando stale es true" do
    stale_forecast = one_day_forecast.merge(stale: true)
    render_inline(described_class.new(forecast: stale_forecast, project: project))
    expect(page).to have_text("desactualizado")
  end
end
