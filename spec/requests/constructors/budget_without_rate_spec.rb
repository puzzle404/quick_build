# frozen_string_literal: true

require "rails_helper"

# Obra con presupuesto en USD y sin cotización disponible (dolarapi caído y
# sin último valor conocido): no se puede comparar contra lo gastado, que está
# en pesos. Las pantallas muestran "—" / "sin cotización", nunca un "0%" ni un
# "$ 0" engañosos, y los totales de la cartera la dejan afuera del %.
RSpec.describe "Presupuesto en USD sin cotización", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let!(:usd) { create(:project, owner: constructor, name: "Obra USD", budget_cents: 50_000_00, budget_currency: "USD") }

  before do
    create(:project_stage, project: usd, spent_cents: 12_000_000_00)
    allow(Money::UsdArsRate).to receive(:current).and_return(nil)
    sign_in(constructor)
  end

  def text
    Nokogiri::HTML(body_without_templates).text.gsub(/\s+/, " ")
  end

  it "la ficha mobile no dice 0% del presupuesto" do
    cookies["qb_mobile_client"] = "1"
    get constructors_project_path(usd)

    expect(text).not_to match(/\b0% de US\$/)
    expect(text).to include("sin cotización")
  end

  it "el header de la obra avisa que no hay cotización" do
    get constructors_project_path(usd)
    expect(text).to include("de US$ 50k · sin cotización")
  end

  it "el reporte muestra el presupuesto en su moneda y no lo cuenta en la ejecución" do
    ars = create(:project, owner: constructor, name: "Obra ARS", status: :in_progress, budget_cents: 100_000_00)
    create(:expense, project: ars, author: constructor, amount_cents: 50_000_00)
    create(:expense, project: usd, author: constructor, amount_cents: 1_000_000_00)
    usd.update!(status: :in_progress)

    get constructors_report_path

    expect(text).to include("US$ 50.000")
    expect(text).to match(/Ejecución presupuestaria\s*50%/)
  end

  it "el CSV de la cartera deja vacíos presupuesto y disponible" do
    get constructors_root_path(format: :csv)

    cells = response.body.lines.find { |l| l.include?("Obra USD") }.strip.split(";", -1)
    expect(cells[9]).to eq("")
    expect(cells[11]).to eq("")
  end
end
