require "rails_helper"

RSpec.describe Qb::Mobile::FormAmountRowComponent, type: :component do
  def value_of(rendered)
    rendered.css("input.m-frow-amount-input").first["value"]
  end

  it "muestra los centavos redondos como pesos enteros, sin separador de miles" do
    rendered = render_inline(described_class.new(label: "Presupuesto", name: "project_stage[budget_pesos]", cents: 150_000_000))

    expect(value_of(rendered)).to eq("1500000")
  end

  # Regresión: `format("%.2f", n)` pelado dentro de un ViewComponent se resuelve
  # contra ViewComponent::Base#format (el de render, sin argumentos) y explota
  # con ArgumentError apenas el importe tiene centavos.
  it "muestra los centavos no redondos con coma decimal, sin explotar" do
    rendered = render_inline(described_class.new(label: "Tarifa", name: "project_person[hourly_rate_pesos]", cents: 520_050))

    expect(value_of(rendered)).to eq("5200,50")
  end

  it "deja el campo vacío cuando no hay importe cargado" do
    rendered = render_inline(described_class.new(label: "Tarifa", name: "project_person[hourly_rate_pesos]", cents: nil))

    expect(value_of(rendered)).to eq("")
  end

  it "respeta el value explícito por encima de los centavos" do
    rendered = render_inline(described_class.new(label: "Total", name: "expense[amount_pesos]", value: "1.500,50", cents: 999))

    expect(value_of(rendered)).to eq("1.500,50")
  end

  it "se tipea siempre como texto con teclado decimal (nunca number ni centavos)" do
    rendered = render_inline(described_class.new(label: "Tarifa", name: "project_person[hourly_rate_pesos]", cents: 450_000, placeholder: "4.500"))
    input = rendered.css("input.m-frow-amount-input").first

    expect(input["type"]).to eq("text")
    expect(input["inputmode"]).to eq("decimal")
    expect(input["name"]).to eq("project_person[hourly_rate_pesos]")
    expect(input["placeholder"]).to eq("4.500")
  end
end
