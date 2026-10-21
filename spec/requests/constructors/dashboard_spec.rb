# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Dashboard", type: :request do
  let(:user) { create(:user, :constructor) }

  describe "GET /constructors (dashboard index)" do
    before do
      Rails.cache.clear
      sign_in(user)
      stub_request(:get, "https://dolarapi.com/v1/dolares")
        .to_return(
          status: 200,
          body: [
            { "casa" => "oficial", "compra" => 1045, "venta" => 1085, "fechaActualizacion" => "2026-05-22T10:00:00Z" },
            { "casa" => "blue",    "compra" => 1200, "venta" => 1250, "fechaActualizacion" => "2026-05-22T10:00:00Z" }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "renderiza el widget de tipo de cambio" do
      get constructors_root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tipo de cambio")
    end

    it "muestra el valor oficial desde la API" do
      get constructors_root_path
      expect(response.body).to include("Oficial")
    end
  end

  describe "GET /constructors.csv (reporte)" do
    it "descarga el CSV con las obras y sus KPIs" do
      create(:project, owner: user, name: "Torre Azul", status: :in_progress)
      sign_in(user)

      get constructors_root_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/csv")
      expect(response.body).to include("Código")
      expect(response.body).to include("Torre Azul")
    end
  end

  describe "GET /constructors/dashboard/evolution_chart" do
    it "renderiza el frame del gráfico con el rango pedido" do
      sign_in(user)

      get constructors_evolution_chart_path(months: 12)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="evolution-chart"')
      expect(response.body).to include("Evolución · 12 meses")
    end
  end
end
