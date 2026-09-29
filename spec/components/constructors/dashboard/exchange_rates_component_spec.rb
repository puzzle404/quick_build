# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Dashboard::ExchangeRatesComponent, type: :component do
  describe "con datos presentes" do
    let(:rates) do
      {
        oficial: { compra: 1045, venta: 1085, fecha: "2026-05-22T10:00:00Z" },
        blue:    { compra: 1200, venta: 1250, fecha: "2026-05-22T10:00:00Z" },
        stale:   false
      }
    end

    it "muestra el título Tipo de cambio" do
      render_inline(described_class.new(rates: rates))
      expect(page).to have_text("Tipo de cambio")
    end

    it "muestra valores de USD oficial (compra y venta)" do
      render_inline(described_class.new(rates: rates))
      expect(page).to have_text("1.045")
      expect(page).to have_text("1.085")
    end

    it "muestra valores de USD blue (compra y venta)" do
      render_inline(described_class.new(rates: rates))
      expect(page).to have_text("1.200")
      expect(page).to have_text("1.250")
    end

    it "no muestra badge desactualizado cuando stale es false" do
      render_inline(described_class.new(rates: rates))
      expect(page).not_to have_text("desactualizado")
    end
  end

  describe "cuando stale" do
    let(:stale_rates) do
      {
        oficial: { compra: 999, venta: 1000, fecha: nil },
        blue:    {},
        stale:   true
      }
    end

    it "muestra badge desactualizado" do
      render_inline(described_class.new(rates: stale_rates))
      expect(page).to have_text("desactualizado")
    end
  end

  describe "sin datos (vacío)" do
    it "muestra empty state cuando rates es nil" do
      render_inline(described_class.new(rates: nil))
      expect(page).to have_text("Tipo de cambio")
      expect(page).to have_text("desactualizado")
    end
  end
end
