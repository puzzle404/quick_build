# frozen_string_literal: true

# Google Maps falso para system specs con JS: los specs no salen a internet ni
# necesitan una key real. Reemplaza `window.google.maps.importLibrary` antes de
# que corra el JS de la página (loadGoogleMaps lo detecta y no carga el script)
# y deja `window.__gmMoveMap(lat, lng)` para simular que el usuario arrastra el
# mapa debajo del pin.
module GoogleMapsStub
  STUB_JS = <<~JS
    (() => {
      const state = window.__gm = { maps: [], queries: [] }
      class LatLng { constructor(lat, lng) { this._lat = lat; this._lng = lng } lat() { return this._lat } lng() { return this._lng } }
      class FakeMap {
        constructor(el, opts) {
          this.center = opts.center; this.zoom = opts.zoom; this.listeners = {}
          el.dataset.fakeMap = "ready"; state.maps.push(this)
          setTimeout(() => this.fire("idle"), 0)
        }
        addListener(name, fn) { (this.listeners[name] ||= []).push(fn); return { remove() {} } }
        fire(name) { (this.listeners[name] || []).forEach((fn) => fn()) }
        getCenter() { return new LatLng(this.center.lat, this.center.lng) }
        setCenter(c) { this.center = c; setTimeout(() => this.fire("idle"), 0) }
        setZoom(z) { this.zoom = z }
      }
      const PREDICTION = {
        text: "Avenida Colón 1234, Mendoza, Argentina", main: "Avenida Colón 1234", secondary: "Mendoza, Argentina",
        address: "Av. Colón 1234, M5500 Mendoza, Argentina", lat: -32.8895, lng: -68.8458
      }
      const toPrediction = (p) => ({
        text: { toString: () => p.text }, mainText: { toString: () => p.main }, secondaryText: { toString: () => p.secondary },
        toPlace: () => ({ async fetchFields() { this.formattedAddress = p.address; this.location = new LatLng(p.lat, p.lng) } })
      })
      const places = {
        AutocompleteSessionToken: class {},
        AutocompleteSuggestion: {
          async fetchAutocompleteSuggestions({ input }) {
            state.queries.push(input)
            return { suggestions: [ { placePrediction: toPrediction(PREDICTION) } ] }
          }
        }
      }
      window.google = { maps: { importLibrary: async (name) => (name === "places" ? places : { Map: FakeMap }) } }
      window.__gmMoveMap = (lat, lng) => { const m = state.maps[state.maps.length - 1]; m.center = { lat, lng }; m.fire("idle") }
    })()
  JS

  def stub_google_maps!
    page.driver.browser.page.command("Page.addScriptToEvaluateOnNewDocument", source: STUB_JS)
  end
end

RSpec.configure do |config|
  config.include GoogleMapsStub, type: :system

  # La meta con la key sólo se renderiza si hay key: `google_maps: true` la
  # simula para el request (el server de Capybara corre en este proceso).
  config.around(:each, :google_maps) do |example|
    previous = ENV["GOOGLE_MAPS_API_KEY"]
    ENV["GOOGLE_MAPS_API_KEY"] = "test-browser-key"
    example.run
  ensure
    ENV["GOOGLE_MAPS_API_KEY"] = previous
  end
end
