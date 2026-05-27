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
end
