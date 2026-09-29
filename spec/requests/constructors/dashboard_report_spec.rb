# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Dashboard reporte y export", type: :request do
  let(:user) { create(:user, :constructor) }

  describe "GET /constructors.csv" do
    it "usa el dialecto de Excel es-AR y toma Gastado de los Expenses reales" do
      project = create(:project, owner: user, name: "Torre Azul", status: :in_progress,
                                 budget_cents: 10_000_000, start_date: Date.new(2026, 3, 1))
      create(:expense, project: project, author: user, amount_cents: 250_000)
      sign_in(user)

      get constructors_root_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.body.bytes.first(3)).to eq([ 0xEF, 0xBB, 0xBF ])

      row = response.body.lines.find { |l| l.include?("Torre Azul") }
      cells = row.strip.split(";")
      expect(cells[1]).to eq("Torre Azul")
      expect(cells[9]).to eq("100000,00")   # Presupuesto
      expect(cells[10]).to eq("2500,00")    # Gastado = Expenses, no spent_cents
      expect(cells[14]).to eq("01/03/2026") # Inicio dd/mm/aaaa
    end

    it "ordena por nombre para que el archivo no cambie entre descargas" do
      create(:project, owner: user, name: "Zeta")
      create(:project, owner: user, name: "Alfa")
      sign_in(user)

      get constructors_root_path(format: :csv)

      names = response.body.lines.drop(1).map { |l| l.split(";")[1] }
      expect(names).to eq([ "Alfa", "Zeta" ])
    end
  end

  describe "GET /constructors/reporte" do
    it "renderiza el reporte imprimible con las obras activas" do
      create(:project, owner: user, name: "Torre Azul", status: :in_progress)
      create(:project, owner: user, name: "Obra Cerrada", status: :completed)
      sign_in(user)

      get constructors_report_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Estado de obras")
      expect(response.body).to include("Detalle por obra")
      expect(response.body).to include("@media print")
      # La tabla deja afuera las finalizadas y lo dice (el sidebar del layout
      # igual las nombra, por eso la aserción va sobre el subtítulo).
      expect(response.body).to include("1 obras activas · 1 finalizadas no listadas")
    end

    it "incluye las finalizadas con ?alcance=todas" do
      create(:project, owner: user, name: "Obra Cerrada", status: :completed)
      sign_in(user)

      get constructors_report_path(alcance: "todas")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Obra Cerrada")
    end
  end
end
