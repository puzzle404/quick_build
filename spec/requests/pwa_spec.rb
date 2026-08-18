# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PWA", type: :request do
  describe "GET /manifest.json" do
    it "serves a valid manifest with required fields and icons" do
      get "/manifest.json"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")

      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Quick Build")
      expect(json["display"]).to eq("standalone")
      expect(json["start_url"]).to eq("/constructors")

      sizes = json["icons"].map { |i| i["sizes"] }
      expect(sizes).to include("192x192", "512x512")
      expect(json["icons"]).to include(a_hash_including("purpose" => "maskable"))
    end
  end

  describe "GET /service-worker" do
    it "serves javascript with a fetch handler (installability)" do
      # Los navegadores piden el SW como script (Accept incluye text/javascript);
      # el request spec por defecto pide HTML, así que fijamos el Accept.
      get "/service-worker", headers: { "Accept" => "text/javascript" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
      expect(response.body).to include('addEventListener("fetch"')
    end

    it "precaches fresh copies and never resolves a navigation without Response" do
      get "/service-worker", headers: { "Accept" => "text/javascript" }

      # Versión nueva del cache (invalida qb-shell-v1 en clientes ya instalados).
      expect(response.body).to include('"qb-shell-v2"')
      # cache: "reload" saltea el cache HTTP del navegador al precachear.
      expect(response.body).to include('cache: "reload"')
      # Guard: caches.match puede resolver undefined; siempre hay fallback.
      expect(response.body).to include("offlineFallbackResponse")
    end
  end

  describe "theme-color (PWA head)" do
    it "emits the graphite bg token by default (anonymous)" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="theme-color" content="#fbfaf8"')
    end

    it "emits the night bg token when the user opted into the night theme" do
      user = create(:user, :constructor, preferences: { "theme" => "night" })
      sign_in(user)

      get "/constructors"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="theme-color" content="#0d1218"')
    end
  end

  describe "GET /offline.html" do
    it "serves the offline fallback page" do
      get "/offline.html"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      # El body llega como ASCII-8BIT (archivo estático); comparamos con ASCII.
      expect(response.body).to include("Reintentar")
    end
  end
end
