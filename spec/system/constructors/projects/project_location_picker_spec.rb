# frozen_string_literal: true

require "rails_helper"

# El picker de ubicación sólo existe con Stimulus + Leaflet, así que va con JS.
RSpec.describe "Project location picker", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }

  # Buenos Aires: bien lejos de Mendoza, así se nota si algo la pisa.
  let(:device_lat) { -34.6037 }
  let(:device_lng) { -58.3816 }

  # Stub de navigator.geolocation inyectado antes de que corra el JS de la
  # página. Va scopeado a esta pestaña (no a `browser.extensions`) para que
  # muera con el reset de Capybara y no se filtre a otros specs.
  def fake_device_location
    page.driver.browser.page.command(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JS
        Object.defineProperty(navigator, "geolocation", {
          configurable: true,
          value: {
            getCurrentPosition(onSuccess) {
              onSuccess({ coords: { latitude: #{device_lat}, longitude: #{device_lng}, accuracy: 10 } })
            },
            watchPosition() { return 0 },
            clearWatch() {}
          }
        })
      JS
    )
  end

  def hidden_value(name)
    find("input[name='project[#{name}]']", visible: false).value.to_f
  end

  it "geolocaliza el alta pero no pisa las coordenadas de una obra ya ubicada" do
    project = create(
      :project,
      owner: constructor,
      location: "Av. Colón 1234, Mendoza",
      latitude: -32.8895,
      longitude: -68.8458
    )

    sign_in_user(constructor)
    fake_device_location

    # Alta nueva: sin coordenadas cargadas, la ubicación del dispositivo sirve
    # como punto de partida. Esto además ancla el tiempo de respuesta del
    # navegador para la segunda parte.
    visit new_constructors_project_path
    expect(page).to have_css("#project-map.leaflet-container", wait: 5)
    expect(page).to have_field("project[latitude]", with: device_lat.to_s, type: :hidden, wait: 5)

    # Edición de una obra YA georreferenciada: la ubicación del navegador no
    # tiene que relocalizar la obra por el solo hecho de abrir el formulario.
    visit edit_constructors_project_path(project)
    expect(page).to have_css("#project-map.leaflet-container", wait: 5)
    # El buscador arranca expandido, con su input a la vista.
    expect(page).to have_css(".leaflet-control-geocoder-expanded input", wait: 5)

    expect(hidden_value("latitude")).to be_within(0.0001).of(-32.8895)
    expect(hidden_value("longitude")).to be_within(0.0001).of(-68.8458)
  end

  # El control sólo sugiere mientras se escribe si el geocoder expone suggest(),
  # y la clase Nominatim del vendor no lo trae: se lo agregamos nosotros. Sin
  # esa línea el buscador queda mudo hasta que apretás Enter, y nada más en la
  # pantalla lo delata. Se chequea acá, sin salir a Nominatim.
  it "deja el buscador sugiriendo mientras se escribe" do
    project = create(:project, owner: constructor, latitude: -32.8895, longitude: -68.8458)

    sign_in_user(constructor)
    visit edit_constructors_project_path(project)
    expect(page).to have_css("#project-map.leaflet-container", wait: 5)

    wired = page.evaluate_script(<<~JS)
      (() => {
        const el = document.querySelector('[data-controller~="project-map"]')
        const ctl = window.Stimulus.getControllerForElementAndIdentifier(el, "project-map")
        return !!(ctl && typeof ctl.searchGeocoder.suggest === "function")
      })()
    JS

    expect(wired).to be(true)
  end
end
