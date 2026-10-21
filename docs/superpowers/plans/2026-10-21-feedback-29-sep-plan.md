# Feedback 29/09 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolver los 11 puntos pendientes del doc "Pruebas en Nuevo proyecto para feedback" (ronda 29/09), con las decisiones que tomó el usuario el 21/10.

**Architecture:** Cambios acotados sobre el Constructor OS (Rails 8 + Hotwire + ViewComponent). La pieza nueva más grande es la moneda del presupuesto: `projects.budget_currency` + `Project#budget_ars_cents` (USD → ARS al dólar oficial venta del día, vía `External::ExchangeRatesFetcher`). Todas las comparaciones contra lo gastado pasan a usar el equivalente en pesos, y lo que se muestra usa la moneda original. El resto son ajustes de drawer, mapa, formularios, Stimulus y vistas.

**Tech Stack:** Rails 8, Turbo 8 / Stimulus (importmap, sin bundler), ViewComponent, Pundit, RSpec + Cuprite, Prawn (nuevo) para el PDF.

**Spec:** este documento. La fuente es el .docx del usuario (ronda 29/09) más las 4 decisiones del 21/10:
1. Presupuesto en ARS o USD; para comparar contra gastos se convierte con la cotización del día.
2. Estado inicial: "Inicio" / "En progreso" (renombrar "Planificado" → "Inicio" en toda la app; "Finalizado" no se ofrece al crear).
3. Lista de materiales: PDF **sin** precios estimados (para pedir cotización); el Excel/CSV queda **con** precios.
4. Landing: fuera de este plan (cuando el usuario mande el contenido real).

## Global Constraints

- Todo lo que está bajo `Constructors::` sigue el design system QB OS de `CLAUDE.md`: tokens CSS (`var(--color-*)`), `Qb::*` primitives, `Qb::BtnComponent` como único botón, `.qb-field/.qb-label/.qb-input/.qb-select`, montos con `Qb::MoneyFieldComponent` / `Qb::Mobile::FormAmountRowComponent`, formatos con `qb_fmt_*`. Nada de clases de paleta Tailwind.
- Vistas desktop y `+mobile` en paralelo: si se toca un form que existe en las dos variantes, se tocan las dos.
- Copy de UI en español rioplatense (voseo), igual que el resto de la app. Comentarios de código en español, con el mismo tono que los existentes.
- Specs: `bundle exec rspec` (CI NO corre RSpec). Request specs que preguntan por el drawer usan `body_without_templates`. JS system specs con `js: true`; Google Maps con `google_maps: true` + `stub_google_maps!`. Nunca red real (WebMock).
- Request y system specs ya tienen dolarapi stubeado (`stub_external_apis`: oficial compra 1045 / venta 1085). Component/decorator/model/service specs que conviertan USD deben stubear `Money::UsdArsRate.current`.
- Mobile en request specs: `cookies["qb_mobile_client"] = "1"` antes del request (no usar un UA de Safari 17: `allow_browser :modern` lo rechaza con 406).
- Commits chicos por tarea, en la rama `feat/feedback-29-sep-2026`, con el trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Obra en USD sin cotización** (dolarapi caído y sin último valor conocido): las comparaciones (salud, % usado, sobrecosto) se apagan — nunca un 0% engañoso ni una división por cero. Test en Task 8.
2. **Editar una obra ya ubicada** no puede mover su pin al centro por defecto, y **una obra nueva en la que nunca se tocó el mapa** no puede guardar coordenadas. Tests en Task 2.
3. **Borrar notas/fotos de etapa desde la Bitácora/Fotos** con la ruta del proyecto no puede alcanzar notas o fotos de OTRA obra (404). Tests en Tasks 10 y 11.
4. **Nota de etapa creada desde la Bitácora en mobile** vuelve a la Bitácora, no a la pantalla de la etapa. Test en Task 10.
5. **PDF con caracteres fuera de Windows-1252** (emoji, otros alfabetos) en nombres/notas de ítems: no puede explotar. Test en Task 7.

---

### Task 1: Un drawer con formulario no se cierra con clic afuera ni con Escape

Feedback: "si se hace click fuera de esta ventana, la ventana desaparece junto con la información cargada… debe quedar ahí hasta que se presione guardar o cancelar".

**Files:**
- Modify: `app/javascript/controllers/qb/drawer_controller.js:291-301` (`backdrop`, `keydown`) + helpers nuevos `_guardsForm`, `_nudge`
- Modify: `app/assets/tailwind/application.css` (keyframes `qb-drawer-nudge`, junto a los estilos `.qb-drawer-*`)
- Modify: `app/components/constructors/projects/materials/list_detail_component.html.erb:156-160` (el alta inline de ítems se marca `data-drawer-dismissable`)
- Modify: `CLAUDE.md` (sección del drawer) — se hace en Task 13
- Test: `spec/system/constructors/drawer_form_guard_spec.rb` (nuevo)

**Interfaces:**
- Produces: atributo `data-drawer-dismissable` en un `<form>` = "este form no bloquea el cierre por clic afuera/Escape". Lo usa Task 6 (misma fila de alta inline).

- [ ] **Step 1: Write the failing test**

```ruby
# spec/system/constructors/drawer_form_guard_spec.rb
# frozen_string_literal: true

require "rails_helper"

# Un drawer con un formulario (alta/edición) sólo se cierra con Guardar,
# Cancelar o la ×: un clic afuera o Escape hacían perder lo cargado
# (feedback 29/09). Las vistas de consulta se siguen cerrando igual que antes.
RSpec.describe "Drawer con formulario", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }

  def drawer_open?
    page.evaluate_script("document.querySelector('#qb_drawer_shell').classList.contains('qb-drawer-open')")
  end

  def click_outside_drawer
    page.execute_script(<<~JS)
      document.querySelector('#qb_drawer_shell .qb-drawer-backdrop')
        .dispatchEvent(new MouseEvent('click', { bubbles: true }))
    JS
  end

  before { sign_in_user(constructor) }

  it "no se cierra con un clic afuera ni con Escape y conserva lo tipeado" do
    visit constructors_project_path(project)
    click_link "Registrar gasto", match: :first
    fill_in "expense[description]", with: "a medio cargar"

    click_outside_drawer
    find_field("expense[description]").send_keys(:escape)
    sleep 0.4

    expect(drawer_open?).to be(true)
    expect(page).to have_field("expense[description]", with: "a medio cargar")

    find(".qb-drawer-close").click
    expect(page).to have_no_field("expense[description]", wait: 5)
    expect(drawer_open?).to be(false)
  end

  it "una vista de consulta (detalle de etapa) sí se cierra con un clic afuera" do
    stage = create(:project_stage, project: project, name: "Replanteo")
    visit constructors_project_path(project, drawer: constructors_project_stage_path(project, stage))
    expect(page).to have_css(".qb-drawer-panel", text: "Replanteo", wait: 5)

    click_outside_drawer

    expect(page).to have_no_css(".qb-drawer-panel", text: "Replanteo", wait: 5)
    expect(drawer_open?).to be(false)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/system/constructors/drawer_form_guard_spec.rb`
Expected: the first example FAILS (the drawer closes and `drawer_open?` is false). The second one PASSES (current behavior).

- [ ] **Step 3: Write minimal implementation**

In `drawer_controller.js` replace `backdrop` and `keydown` (lines 291-301) with:

```js
  backdrop(event) {
    if (this.hasPanelTarget && this.panelTarget.contains(event.target)) return
    if (this._guardsForm()) return this._nudge()
    this.close()
  }

  keydown(event) {
    if (event.key !== "Escape" || !this._isOpen()) return
    event.preventDefault()
    if (this._guardsForm()) return this._nudge()
    this.close()
  }

  // Un alta/edición abierta sólo se cierra con Guardar, Cancelar o la ×: un
  // clic afuera o Escape tiraban todo lo cargado (feedback 29/09). Las vistas
  // de consulta se siguen cerrando como siempre. `button_to` también es un
  // <form> (acciones sueltas, no hay nada tipeado) y una vista de consulta
  // con un form chico embebido —el alta inline de ítems de una lista— lo
  // marca con data-drawer-dismissable.
  _guardsForm() {
    const scope = this.hasPanelTarget ? this.panelTarget : (this.hasDialogTarget ? this.dialogTarget : null)
    return !!scope?.querySelector("form:not(.button_to):not([data-drawer-dismissable])")
  }

  // El clic llegó pero el panel no se cierra: un sacudón corto lo hace notar.
  _nudge() {
    if (!this.hasPanelTarget) return
    const panel = this.panelTarget
    panel.classList.remove("qb-drawer-nudge")
    void panel.offsetWidth // reinicia la animación si se repite el clic
    panel.classList.add("qb-drawer-nudge")
  }
```

Also update the comment above `close()` (line 277) from "Cierre disparado por el botón × / backdrop / Escape" to "Cierre disparado por el botón × (y por backdrop / Escape en vistas sin formulario)".

In `application.css`, next to the `.qb-drawer-panel` rules, add:

```css
/* Clic afuera / Escape con un formulario abierto: el drawer no se cierra
   (qb--drawer#_guardsForm) y lo hace notar con un sacudón corto. */
@keyframes qb-drawer-nudge {
  0%, 100% { translate: 0; }
  30% { translate: -6px 0; }
  60% { translate: 3px 0; }
}
.qb-drawer-nudge { animation: qb-drawer-nudge 260ms ease-out; }
@media (prefers-reduced-motion: reduce) { .qb-drawer-nudge { animation: none; } }
```

(`translate` and not `transform`: the panel's slide-in uses `transform`, and animating it would fight the open state.)

In `list_detail_component.html.erb`, the inline add `form_with` (line ~160) changes `data: { turbo_frame: 'drawer' }` to:

```erb
                    data: { turbo_frame: 'drawer', drawer_dismissable: true },
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/system/constructors/drawer_form_guard_spec.rb spec/system/constructors/drawer_persistence_spec.rb spec/system/project_memberships_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/qb/drawer_controller.js app/assets/tailwind/application.css \
  app/components/constructors/projects/materials/list_detail_component.html.erb \
  spec/system/constructors/drawer_form_guard_spec.rb
git commit -m "fix(drawer): un formulario abierto no se cierra con clic afuera ni Escape"
```

---

### Task 2: El mapa se ve desde el principio en el alta/edición de obra

Feedback: "recién me apareció el mapa una vez que puse la dirección. Debería poder ubicarse en el mapa si no se conoce la dirección exacta."

Regla clave: mostrar el mapa NO es ubicar la obra. Las coordenadas se escriben sólo si (a) la obra ya estaba ubicada, (b) el usuario eligió una sugerencia, (c) el usuario arrastró el mapa, o (d) usó "Usar mi ubicación actual". Hoy `showMap` y el primer `idle` escriben el centro siempre.

**Files:**
- Modify: `app/views/constructors/projects/_location_fields.html.erb` (mapa visible, valor `fallback-center`, botón "Usar mi ubicación actual" en lugar de "¿No encontrás la dirección?…")
- Modify: `app/javascript/controllers/project_map_controller.js` (flag `placed`, `dragstart`, `locate()`, centro inicial)
- Modify: `app/helpers/quickbuild_helper.rb` (`qb_map_fallback_center`)
- Modify: `spec/support/google_maps_stub.rb` (`__gmMoveMap` dispara `dragstart`)
- Modify: `spec/system/constructors/projects/project_location_picker_spec.rb`, `spec/system/constructors/projects/new_project_wizard_spec.rb:23`, comment in `spec/system/projects_spec.rb:36-37`
- Test: `spec/helpers/quickbuild_helper_spec.rb` (fallback center)

**Interfaces:**
- Produces: `qb_map_fallback_center` → `{ lat: Float, lng: Float }` or `nil` (the user's last located project).

- [ ] **Step 1: Write the failing tests**

In `project_location_picker_spec.rb`:

1. In the first example, replace line 22 (`expect(page).to have_no_css("#project-map", visible: :visible) …`) with:

```ruby
    # El mapa está desde el principio, pero mostrarlo no ubica la obra.
    expect(page).to have_css("#project-map[data-fake-map='ready']", wait: 5)
    expect(find("input[name='project[latitude]']", visible: false).value).to eq("")
```

2. Replace the last example ("sin dirección exacta se puede marcar…", lines 71-80) with these three:

```ruby
  it "sin dirección exacta se marca la obra moviendo el mapa" do
    visit new_constructors_project_path
    expect(page).to have_css("#project-map[data-fake-map='ready']", wait: 5)

    page.execute_script("window.__gmMoveMap(-33.0, -68.9)")

    expect(hidden_value("latitude")).to be_within(0.0001).of(-33.0)
    expect(page).to have_field("project[location]", with: "")
  end

  it "si nunca se toca el mapa, la obra se guarda sin coordenadas" do
    visit new_constructors_project_path
    expect(page).to have_css("#project-map[data-fake-map='ready']", wait: 5)

    fill_in "project[name]", with: "Obra sin ubicar"
    click_button "Crear proyecto"

    expect(page).to have_content("Obra sin ubicar", wait: 5)
    expect(constructor.owned_projects.find_by!(name: "Obra sin ubicar").latitude).to be_nil
  end

  it "«Usar mi ubicación actual» centra el mapa donde está el usuario y lo marca" do
    visit new_constructors_project_path
    expect(page).to have_css("#project-map[data-fake-map='ready']", wait: 5)
    page.execute_script(<<~JS)
      Object.defineProperty(navigator, "geolocation", { configurable: true, value: {
        getCurrentPosition: (ok) => ok({ coords: { latitude: -32.95, longitude: -68.85 } })
      } })
    JS

    click_button "Usar mi ubicación actual"

    expect(page).to have_css("input[name='project[latitude]'][value^='-32.95']", visible: false, wait: 5)
    expect(hidden_value("longitude")).to be_within(0.0001).of(-68.85)
  end
```

In `new_project_wizard_spec.rb:23` replace the expected button with:

```ruby
    expect(page).to have_button("Usar mi ubicación actual")
```

In `spec/helpers/quickbuild_helper_spec.rb` add:

```ruby
  describe "#qb_map_fallback_center" do
    let(:user) { create(:user, :constructor) }

    before { allow(helper).to receive(:current_user).and_return(user) }

    it "es nil si el usuario no tiene obras ubicadas" do
      create(:project, owner: user, latitude: nil, longitude: nil)
      expect(helper.qb_map_fallback_center).to be_nil
    end

    it "devuelve el punto de la última obra ubicada" do
      create(:project, owner: user, latitude: -34.6, longitude: -58.4, updated_at: 2.days.ago)
      create(:project, owner: user, latitude: -32.89, longitude: -68.84, updated_at: 1.hour.ago)
      expect(helper.qb_map_fallback_center).to eq(lat: -32.89, lng: -68.84)
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/system/constructors/projects/project_location_picker_spec.rb spec/system/constructors/projects/new_project_wizard_spec.rb spec/helpers/quickbuild_helper_spec.rb`
Expected: FAIL — the map is hidden at start, there is no "Usar mi ubicación actual" button, and `qb_map_fallback_center` is undefined.

- [ ] **Step 3: Implement**

`quickbuild_helper.rb` — add:

```ruby
  # Centro inicial del mapa de una obra todavía sin ubicar: la última obra
  # ubicada del usuario (casi siempre trabaja en la misma zona). nil = el
  # controller usa su centro por defecto.
  def qb_map_fallback_center
    point = current_user&.accessible_projects
                       &.where&.not(latitude: nil)&.where&.not(longitude: nil)
                       &.reorder(updated_at: :desc)&.pick(:latitude, :longitude)
    point && { lat: point[0], lng: point[1] }
  end
```

(Two chained `where.not` calls, not `where.not(latitude: nil, longitude: nil)`: with two keys Rails generates `NOT (a AND b)`, which lets through projects with only one of the two coordinates.)

`_location_fields.html.erb`:
- Update the header comment: "2. El mapa está siempre a la vista (pin fijo al centro): elegir una sugerencia lo centra ahí; si no hay dirección exacta se mueve el mapa hasta la obra o se usa la ubicación actual. Mostrar el mapa no ubica la obra: las coordenadas se guardan recién cuando el usuario la marca."
- Root: `<div data-controller="project-map" data-project-map-fallback-center-value="<%= qb_map_fallback_center.to_json %>">`
- Delete `located` (line 9) and the `<%= "hidden" unless located %>` on `mapWrap` (line 26).
- Caption under the map: `Mové el mapa para dejar el pin justo sobre la obra. ¿No sabés la dirección exacta? Buscá la zona y marcala acá.`
- Replace the `manualButton` block (lines 44-49) with:

```erb
  <div style="margin-top:8px;">
    <button type="button" data-project-map-target="locateButton" data-action="project-map#locate"
            style="display:inline-flex;align-items:center;gap:5px;background:none;border:none;padding:0;font-size:11.5px;color:var(--color-accent);cursor:pointer;">
      <%= render Qb::IconComponent.new(name: :pin, size: 12) %> Usar mi ubicación actual
    </button>
  </div>
```

(Check that `Qb::IconComponent` has `:pin`. If not, use one listed in `app/components/qb/icon_component.rb` that reads as location, or no icon.)

`project_map_controller.js`:
- `static targets`: change `"manualButton"` to `"locateButton"`. Add `static values = { fallbackCenter: Object }`.
- Constant: `const START_ZOOM = 12`.
- `connect()`:

```js
  connect() {
    this.suggestionsList = []
    this.activeIndex = -1
    this.anchor = null // punto de la dirección elegida
    // ¿El usuario ya ubicó la obra? Mostrar el mapa no cuenta: hasta que
    // elija una dirección, mueva el mapa o use su ubicación, no se guardan
    // coordenadas (si no, toda obra nueva quedaba "ubicada" en el centro).
    this.placed = false

    if (!googleMapsAvailable()) {
      this.unavailableTarget.hidden = false
      this.mapWrapTarget.hidden = true
      if (this.hasLocateButtonTarget) this.locateButtonTarget.hidden = true
      return
    }
    const saved = this.savedLatLng
    this.placed = !!saved
    this.showMap(saved || this.startCenter, { zoom: saved ? LOCATED_ZOOM : START_ZOOM })
  }

  get startCenter() {
    const c = this.fallbackCenterValue
    return Number.isFinite(c?.lat) && Number.isFinite(c?.lng) ? c : DEFAULT_CENTER
  }
```

- `choose()`: before `await this.showMap(point, …)` add `this.placed = true`.
- Delete `manual()` and its comment. Add:

```js
  // "Usar mi ubicación actual": para cargar la obra parado en el terreno
  // (lotes, barrios sin numeración). Centra el mapa ahí y la da por ubicada.
  locate(event) {
    event?.preventDefault()
    if (!navigator.geolocation) return this.showNotice("Este navegador no permite obtener tu ubicación.")

    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        this.anchor = null
        this.placed = true
        this.showMap({ lat: coords.latitude, lng: coords.longitude }, { zoom: LOCATED_ZOOM })
      },
      () => this.showNotice("No pudimos obtener tu ubicación. Mové el mapa hasta la obra."),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  showNotice(text) {
    this.hintTarget.textContent = text
    this.hintTarget.hidden = false
  }
```

- `showMap()`: after creating the map (next to `idleListener`) add:
  `this.dragListener = this.map.addListener("dragstart", () => { this.placed = true })`
  and replace the last two lines (`this.writeCoordinates(point); this.updateHint(point)`) with:

```js
    if (!this.placed) return
    this.writeCoordinates(point)
    this.updateHint(point)
```

- `syncFromMap()`: first line `if (!this.placed) return`.
- `disconnect()`: add `this.dragListener?.remove()`.
- Update the file header comment (points 1-3) to describe the map as always visible and the `placed` rule.

`google_maps_stub.rb` line 43: `__gmMoveMap` simulates a real drag:

```js
      window.__gmMoveMap = (lat, lng) => { const m = state.maps[state.maps.length - 1]; m.fire("dragstart"); m.center = { lat, lng }; m.fire("idle") }
```

and update the module comment ("…simular que el usuario arrastra el mapa (dragstart + idle)…").

`spec/system/projects_spec.rb:36-37`: change the comment "el mapa arranca oculto hasta elegir una dirección" to "el mapa se monta con JS; sin JS sólo está el contenedor".

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/system/constructors/projects/project_location_picker_spec.rb spec/system/constructors/projects/new_project_wizard_spec.rb spec/helpers/quickbuild_helper_spec.rb spec/system/projects_spec.rb`
Expected: PASS (including "una obra ya ubicada abre el mapa en su punto", which must not change).

- [ ] **Step 5: Commit**

```bash
git add app/views/constructors/projects/_location_fields.html.erb app/javascript/controllers/project_map_controller.js \
  app/helpers/quickbuild_helper.rb spec/support/google_maps_stub.rb spec/system/constructors/projects/ \
  spec/system/projects_spec.rb spec/helpers/quickbuild_helper_spec.rb
git commit -m "feat(obra): mapa visible desde el alta, ubicación actual y sin coordenadas fantasma"
```

---

### Task 3: Estado "Inicio" y alta sin "Finalizado"

**Files:**
- Modify: `app/models/project.rb:7-15`
- Modify: `app/controllers/constructors/projects_controller.rb` (`create`: guard)
- Modify: `app/views/constructors/projects/new.html.erb:34,105`, `new.html+mobile.erb:39-42` → `status_options(for_create: true)`
- Modify labels: `app/views/constructors/projects/index.html.erb:5`, `index.html+mobile.erb:42`, `app/views/constructors/dashboard/index.html.erb:69-71`, `dashboard/index.html+mobile.erb:72`, `dashboard/report.html.erb:96`
- Modify: `app/views/constructors/projects/edit.html.erb:44` (`status.humanize` → `status_label`), `app/helpers/constructors/projects_helper.rb:8-13` (`project_status_badge` → `Project::STATUS_LABELS`)
- Modify specs: `spec/system/constructors/redesign/projects_list_spec.rb:17`, `spec/system/constructors/redesign/dashboard_spec.rb:17`
- Test: `spec/models/project_spec.rb`, `spec/requests/constructors/projects_spec.rb`

**Interfaces:**
- Produces: `Project::CREATE_STATUSES = %w[planned in_progress]`, `Project.status_options(for_create: false)`.

- [ ] **Step 1: Write the failing tests**

`spec/models/project_spec.rb`:

```ruby
  describe ".status_options" do
    it "rotula planned como «Inicio»" do
      expect(described_class.status_options).to include([ "Inicio", "planned" ])
    end

    it "al crear no ofrece «Finalizado»" do
      expect(described_class.status_options(for_create: true)).to eq([ [ "Inicio", "planned" ], [ "En progreso", "in_progress" ] ])
    end
  end
```

`spec/requests/constructors/projects_spec.rb` (new `describe`, using that file's `sign_in` helper):

```ruby
  describe "alta de obra" do
    let(:constructor) { create(:user, :constructor) }

    before { sign_in(constructor) }

    it "el select de estado inicial no ofrece Finalizado" do
      get new_constructors_project_path
      expect(response.body).to include(">Inicio</option>")
      expect(response.body).not_to include(">Finalizado</option>")
    end

    it "una obra no puede nacer finalizada aunque se fuerce el parámetro" do
      post constructors_projects_path, params: { project: { name: "Obra X", status: "completed" } }
      expect(constructor.owned_projects.find_by!(name: "Obra X")).to be_planned
    end
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/models/project_spec.rb spec/requests/constructors/projects_spec.rb`
Expected: FAIL ("Planificado" instead of "Inicio", no `for_create:` keyword, the project is created as `completed`).

- [ ] **Step 3: Implement**

`project.rb`:

```ruby
  # Etiquetas es-AR de los estados. Fuente única: el decorator y los selects
  # de los forms (desktop y mobile) las leen de acá para no divergir.
  # "Inicio" (antes "Planificado"): pedido del usuario, feedback 29/09.
  STATUS_LABELS = {
    "planned" => "Inicio",
    "in_progress" => "En progreso",
    "completed" => "Finalizado"
  }.freeze

  # Una obra no nace finalizada: el alta sólo ofrece estos.
  CREATE_STATUSES = %w[planned in_progress].freeze

  def self.status_options(for_create: false)
    keys = for_create ? CREATE_STATUSES : statuses.keys
    keys.map { |s| [ STATUS_LABELS.fetch(s, s.humanize), s ] }
  end
```

`projects_controller.rb#create`, right after `@project = current_user.owned_projects.build(project_params)`:

```ruby
    # El select ya no ofrece "Finalizado", pero el parámetro se puede forzar.
    @project.status = "planned" unless Project::CREATE_STATUSES.include?(@project.status)
```

The three create selects: `Project.status_options` → `Project.status_options(for_create: true)`.

Labels (project status only — NOT `planned_progress`, "plan NN%", "Planificación", stage statuses):
- `projects/index.html.erb:5`: `l: 'Planificados'` → `l: 'En inicio'`
- `projects/index.html+mobile.erb:42`: `label: 'Planificados'` → `label: 'En inicio'`
- `dashboard/index.html.erb:69-71`: `label: 'En inicio'`, `hint: 'por arrancar'`, `cta_label: 'Ver en inicio'`
- `dashboard/index.html+mobile.erb:72`: `label: "En inicio"`
- `dashboard/report.html.erb:96`: `label: 'En inicio'`
- `projects/edit.html.erb:44`: `@project_summary.status.humanize` → `@project_summary.status_label`
- `projects_helper.rb` `project_status_badge`: replace `project.status.humanize` with `Project::STATUS_LABELS.fetch(project.status.to_s, project.status.to_s.humanize)`

Specs: `projects_list_spec.rb:17` `'Planificados'` → `'En inicio'`; `dashboard_spec.rb:17` `'Planificadas'` → `'En inicio'`.

Final sweep: `grep -rn "Planificad" app/ spec/` — what remains must be about plan/progress/stages, not project status.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/models/project_spec.rb spec/requests/constructors/projects_spec.rb spec/system/constructors/redesign/ spec/decorators/project_decorator_spec.rb spec/system/projects_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/models/project.rb app/controllers/constructors/projects_controller.rb app/views/constructors/ \
  app/helpers/constructors/projects_helper.rb spec/
git commit -m "feat(obra): estado «Inicio» y el alta no ofrece «Finalizado»"
```

---

### Task 4: Etapa — responsable y presupuesto desde el alta

**Files:**
- Modify: `app/components/constructors/projects/stages/stage_form_component.rb:6-9,29-33`
- Modify: `app/components/constructors/projects/stages/stage_form_component.html.erb:43-70`
- Modify: `app/views/constructors/projects/stages/new.html+mobile.erb` (new "Seguimiento" group)
- Modify: `spec/requests/constructors/stage_tracking_fields_spec.rb:23`
- Test: `spec/requests/constructors/projects/stages_spec.rb`

**Interfaces:**
- Produces: `StageFormComponent#progress_field?` (replaces `tracking_fields?`).

- [ ] **Step 1: Write the failing tests**

`stage_tracking_fields_spec.rb`, replace the example at l.23 ("no muestra el bloque Seguimiento al crear") with:

```ruby
  it "al crear pide responsable y presupuesto, pero no el avance" do
    get new_constructors_project_stage_path(project), headers: { "Turbo-Frame" => "drawer" }

    expect(response.body).to include("project_stage[lead]")
    expect(response.body).to include("project_stage[budget_pesos]")
    expect(response.body).not_to include("project_stage[progress]")
  end
```

`spec/requests/constructors/projects/stages_spec.rb`:

```ruby
  it "crea la etapa con responsable y presupuesto" do
    post constructors_project_stages_path(project), params: {
      project_stage: { name: "Replanteo", lead: "Miguel Lopez", budget_pesos: "1.500.000" }
    }

    stage = project.project_stages.find_by!(name: "Replanteo")
    expect(stage.lead).to eq("Miguel Lopez")
    expect(stage.budget_cents).to eq(150_000_000)
  end

  it "el alta mobile también pide responsable y presupuesto" do
    cookies["qb_mobile_client"] = "1"
    get new_constructors_project_stage_path(project)

    expect(response.body).to include('name="project_stage[lead]"')
    expect(response.body).to include('name="project_stage[budget_pesos]"')
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/constructors/stage_tracking_fields_spec.rb spec/requests/constructors/projects/stages_spec.rb`
Expected: the two "pide responsable…" examples FAIL. "crea la etapa con…" may already pass, because the controller permits those fields; it pins the behavior.

- [ ] **Step 3: Implement**

`stage_form_component.rb`: rename `tracking_fields?` to `progress_field?` and change its comment to:

```ruby
        # El avance sólo al editar: una etapa nueva arranca en 0. Responsable y
        # presupuesto se cargan desde el alta (feedback 29/09: el presupuesto
        # sólo se podía poner después de crearla).
        def progress_field?
          stage.persisted?
        end
```

Update the class comment at l.6-9 (the "Seguimiento" group is shown always; only progress waits for edit).

`stage_form_component.html.erb`, replace the whole block at l.43-70 with:

```erb
  <%# Seguimiento: responsable y presupuesto desde el alta; el avance (con su
      barra) sólo al editar. Los tres los muestra el resto de la app (card,
      drawer, Gantt, CSV, curva S). %>
  <%= render Qb::FormGroupComponent.new(title: 'Seguimiento') do %>
    <div style="display:grid;grid-template-columns:<%= progress_field? ? '110px 1fr' : '1fr' %>;gap:12px;">
      <% if progress_field? %>
        <div class="qb-field" style="margin-bottom:0;">
          <%= form.label :progress, "Avance (%)", class: "qb-label" %>
          <%= form.number_field :progress, in: 0..100, step: 1, **field_opts(:progress) %>
        </div>
      <% end %>
      <div class="qb-field" style="margin-bottom:0;">
        <%= form.label :lead, "Responsable", class: "qb-label" %>
        <%= form.text_field :lead, placeholder: "Ej: Juan Pérez", **field_opts(:lead) %>
      </div>
    </div>

    <% if progress_field? %>
      <div style="margin:10px 0 12px;">
        <%= render Qb::BarComponent.new(value: progress_value, tone: progress_value >= 100 ? :ok : :accent, height: 6) %>
        <p style="margin:4px 0 0;font-size:11px;color:var(--color-ink-4);">Avance guardado: <%= progress_value %>%.</p>
      </div>
    <% end %>

    <div class="qb-field" style="margin:<%= progress_field? ? '0' : '12px 0 0' %>;">
      <%= form.label :budget_pesos, "Presupuesto de la etapa", class: "qb-label" %>
      <%= render Qb::MoneyFieldComponent.new(form: form, method: :budget_pesos, value: budget_pesos_value) %>
      <p style="margin:0;font-size:11px;color:var(--color-ink-4);">En pesos. Se compara contra lo gastado en la curva S y en el detalle.</p>
    </div>
  <% end %>
```

`new.html+mobile.erb`: between the "Cronograma" group and the buttons div, add:

```erb
    <%# Responsable y presupuesto desde el alta (feedback 29/09), igual que
        el form de edición mobile. %>
    <%= render Qb::Mobile::FormGroupComponent.new(title: "Seguimiento") do %>
      <%= render Qb::Mobile::FormRowComponent.new(
            label: "Responsable", name: "project_stage[lead]",
            value: @stage.lead, placeholder: "Ej: Juan Pérez") %>
      <%= render Qb::Mobile::FormAmountRowComponent.new(
            label: "Presupuesto de la etapa", name: "project_stage[budget_pesos]",
            cents: @stage.budget_cents, placeholder: "1.500.000",
            sub: "En pesos (ej: 1.500.000 o 1.500,50).") %>
    <% end %>
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/constructors/stage_tracking_fields_spec.rb spec/requests/constructors/projects/stages_spec.rb spec/components/constructors/projects/stages/ spec/requests/constructors/editable_tracking_fields_spec.rb spec/system/constructors/projects/stages/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/components/constructors/projects/stages/ app/views/constructors/projects/stages/new.html+mobile.erb spec/requests/
git commit -m "feat(etapas): responsable y presupuesto desde el alta de la etapa"
```

---

### Task 5: Editar una etapa actualiza la tarjeta y el Gantt de atrás

Bug: "pude asignar el Responsable… pero en el panel general figura 'Sin asignar'". Cause: `stages#update` (turbo_stream) only re-renders the drawer, so the card and the Gantt behind it stay stale until reload. Also on mobile (no drawer frame) saving showed nothing.

**Files:**
- Modify: `app/controllers/constructors/projects/stages_controller.rb:76-96` (+ private `planning_streams`)
- Modify: `app/views/constructors/projects/show.html.erb:115-118` (id `planning_gantt` on the Gantt wrapper)
- Test: `spec/requests/constructors/projects/stages_spec.rb`, `spec/system/constructors/projects/planning_stage_drawer_spec.rb`

**Interfaces:**
- Consumes: `Constructors::Projects::Planning::StageCardComponent.new(project:, stage:, sub_stages:, expense_totals:)`, `GanttComponent.new(project:, root_stages:, expense_totals:)`, `Projects::SpendSummary#by_stage`.
- Produces: the id `planning_gantt` in `projects#show`.

- [ ] **Step 1: Write the failing tests**

`spec/requests/constructors/projects/stages_spec.rb`:

```ruby
  describe "PATCH update (drawer)" do
    let!(:root) { create(:project_stage, project: project, name: "Estructura") }
    let!(:sub) { create(:project_stage, project: project, parent: root, name: "Columnas") }
    let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html" } }

    it "re-renderiza la tarjeta y el Gantt detrás del drawer con el responsable nuevo" do
      patch constructors_project_stage_path(project, root),
            params: { project_stage: { lead: "Miguel Lopez" } }, headers: turbo

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%(action="update" target="drawer"))
      expect(response.body).to include(%(action="replace" target="card_project_stage_#{root.id}"))
      expect(response.body).to include(%(action="update" target="planning_gantt"))
      expect(response.body.scan("Miguel Lopez").size).to be >= 2 # drawer + tarjeta
    end

    it "editar una sub-etapa reemplaza la tarjeta de su etapa raíz" do
      patch constructors_project_stage_path(project, sub),
            params: { project_stage: { lead: "Ana" } }, headers: turbo

      expect(response.body).to include(%(target="card_project_stage_#{root.id}"))
    end

    it "en mobile (sin drawer) vuelve a la etapa con el aviso" do
      cookies["qb_mobile_client"] = "1"
      patch constructors_project_stage_path(project, root),
            params: { project_stage: { lead: "Miguel Lopez" } }, headers: turbo

      expect(response).to redirect_to(constructors_project_stage_path(project, root))
      expect(flash[:notice]).to eq("Etapa actualizada correctamente.")
    end
  end
```

`spec/system/constructors/projects/planning_stage_drawer_spec.rb` (read the file first and reuse its setup and how it opens the drawer) — add:

```ruby
  it "al guardar la edición, la tarjeta de atrás muestra el responsable nuevo" do
    stage = create(:project_stage, project: project, name: "Replanteo", lead: nil)
    visit constructors_project_path(project, drawer: edit_constructors_project_stage_path(project, stage))
    fill_in "project_stage[lead]", with: "Miguel Lopez", wait: 5
    click_button "Actualizar etapa"

    expect(page).to have_css("#card_project_stage_#{stage.id}", text: "Miguel Lopez", wait: 5)
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/constructors/projects/stages_spec.rb spec/system/constructors/projects/planning_stage_drawer_spec.rb`
Expected: FAIL (there is no `replace` of the card or `planning_gantt`; mobile gets a 200 turbo_stream instead of a redirect).

- [ ] **Step 3: Implement**

`show.html.erb:117`: `<div style="min-width:960px;">` → `<div id="planning_gantt" style="min-width:960px;">`.

`stages_controller.rb#update`, the turbo_stream branch:

```ruby
            format.turbo_stream do
              if mobile_variant?
                # El layout mobile no tiene frame "drawer": el update("drawer")
                # no pintaba nada y el usuario se quedaba en el form sin
                # enterarse de que se guardó.
                redirect_to constructors_project_stage_path(@project, @stage), notice: "Etapa actualizada correctamente."
              else
                @stage.reload
                render turbo_stream: [
                  turbo_stream.update("drawer",
                    partial: "constructors/projects/stages/detail_drawer",
                    locals: {
                      project: @project.decorate,
                      stage: @stage.decorate,
                      sub_stages: @stage.sub_stages.order(:position, :name)
                    }),
                  *planning_streams
                ]
              end
            end
```

Private method (next to `set_stage`):

```ruby
      # Lo que quedó detrás del drawer en projects#show —la tarjeta de la etapa
      # raíz y el Gantt— se re-renderiza en el lugar: antes sólo se actualizaba
      # el drawer y la tarjeta seguía diciendo "Sin asignar" hasta recargar
      # (feedback 29/09). En otras pantallas esos ids no existen y Turbo
      # ignora los streams.
      def planning_streams
        roots = @project.project_stages.where(parent_id: nil).order(:position).includes(:sub_stages).to_a
        totals = ::Projects::SpendSummary.new(@project).by_stage
        project = @project.decorate
        streams = [
          turbo_stream.update("planning_gantt",
            Constructors::Projects::Planning::GanttComponent.new(project: project, root_stages: roots, expense_totals: totals))
        ]

        root = roots.find { |r| r.id == (@stage.parent_id || @stage.id) }
        return streams unless root

        sub_stages = root.sub_stages.sort_by { |s| [ s.position.to_i, s.name.to_s ] }
        streams.unshift turbo_stream.replace(ActionView::RecordIdentifier.dom_id(root, :card),
          Constructors::Projects::Planning::StageCardComponent.new(project: project, stage: root,
                                                                    sub_stages: sub_stages, expense_totals: totals))
      end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/constructors/projects/stages_spec.rb spec/system/constructors/projects/planning_stage_drawer_spec.rb spec/requests/constructors/stage_tracking_fields_spec.rb spec/requests/constructors/editable_tracking_fields_spec.rb spec/components/constructors/projects/planning/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/controllers/constructors/projects/stages_controller.rb app/views/constructors/projects/show.html.erb spec/
git commit -m "fix(etapas): editar una etapa actualiza la tarjeta y el Gantt de atrás; mobile vuelve a la etapa"
```

---

### Task 6: Subtotal en vivo al agregar un material

**Files:**
- Create: `app/javascript/controllers/qb/line_subtotal_controller.js`
- Modify: `app/components/constructors/projects/materials/list_detail_component.html.erb:156-176`
- Test: `spec/system/constructors/projects/material_item_subtotal_spec.rb` (new)

**Interfaces:**
- Consumes: `data-drawer-dismissable` on the same form (Task 1). Keep it.
- Produces: Stimulus `qb--line-subtotal` (targets `quantity`, `price`, `output`; action `recalc`).

- [ ] **Step 1: Write the failing test**

```ruby
# spec/system/constructors/projects/material_item_subtotal_spec.rb
# frozen_string_literal: true

require "rails_helper"

# La fila "agregar ítem" calcula el subtotal mientras se tipea (antes recién
# aparecía al guardar). Mismo formato corto que qb_fmt_cents.
RSpec.describe "Subtotal en vivo de un ítem de materiales", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let(:list) { create(:material_list, project: project, author: constructor) }

  it "muestra cantidad × precio antes de guardar" do
    sign_in_user(constructor)
    visit constructors_project_material_lists_path(project, drawer: constructors_project_material_list_path(project, list))

    output = find("[data-qb--line-subtotal-target='output']", wait: 5)
    expect(output).to have_text("—")

    fill_in "material_item[quantity]", with: "10"
    fill_in "material_item[estimated_cost_pesos]", with: "1500"

    expect(output).to have_text("$ 15k")
  end
end
```

(Check `spec/factories/material_lists.rb` for the right attribute names: `author`, etc.)

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/system/constructors/projects/material_item_subtotal_spec.rb`
Expected: FAIL (there is no `[data-qb--line-subtotal-target='output']`).

- [ ] **Step 3: Implement**

`app/javascript/controllers/qb/line_subtotal_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Subtotal en vivo de la fila "agregar ítem" de una lista de materiales:
// cantidad × precio unitario mientras se tipea (antes aparecía recién al
// guardar — feedback 29/09). Mismo formato corto que qb_fmt_cents:
// "$ 2.5M" / "$ 45k" / "$ 800".
export default class extends Controller {
  static targets = ["quantity", "price", "output"]

  connect() {
    this.recalc()
  }

  recalc() {
    const quantity = parseFloat(this.quantityTarget.value)
    const pesos = parseMoney(this.priceTarget.value)
    if (!Number.isFinite(quantity) || !Number.isFinite(pesos)) {
      this.outputTarget.textContent = "—"
      return
    }
    const cents = Math.round(quantity * Math.round(pesos * 100))
    this.outputTarget.textContent = formatCents(cents)
  }
}

// El campo de precio viene con la máscara es-AR de qb--money-input
// ("1.500.000,5"): puntos de miles, coma decimal.
function parseMoney(value) {
  const normalized = (value || "").replace(/\./g, "").replace(",", ".")
  return normalized.trim() === "" ? NaN : parseFloat(normalized)
}

function formatCents(cents) {
  const n = Math.round(cents / 100)
  const abs = Math.abs(n)
  if (abs >= 1_000_000) return `$ ${(n / 1_000_000).toFixed(1)}M`
  if (abs >= 1_000) return `$ ${Math.round(n / 1_000)}k`
  return `$ ${n}`
}
```

(No registration needed: `eagerLoadControllersFrom` loads every file under `app/javascript/controllers/`. `qb/line_subtotal_controller.js` becomes `qb--line-subtotal`.)

`list_detail_component.html.erb`, in the inline `form_with`:
- `data: { turbo_frame: 'drawer', drawer_dismissable: true, controller: 'qb--line-subtotal' },`
- quantity: add `data: { 'qb--line-subtotal-target': 'quantity', action: 'input->qb--line-subtotal#recalc' }` to `f.number_field :quantity`.
- money field: add `data: { 'qb--line-subtotal-target': 'price', action: 'input->qb--line-subtotal#recalc' }` to `Qb::MoneyFieldComponent.new(...)`. `input_options` merges `data`; the mask's action runs first, so `recalc` reads the already-formatted value.
- the subtotal placeholder (`<span …>—</span>`, line ~172) becomes:
  `<span class="qb-mono qb-tnum" style="text-align:right;color:var(--color-ink-2);" data-qb--line-subtotal-target="output" aria-live="polite">—</span>`

Update the comment above the form (subtotal en vivo + `data-drawer-dismissable`).

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/system/constructors/projects/material_item_subtotal_spec.rb spec/requests/constructors/projects/material_items_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/qb/line_subtotal_controller.js \
  app/components/constructors/projects/materials/list_detail_component.html.erb \
  spec/system/constructors/projects/material_item_subtotal_spec.rb
git commit -m "feat(materiales): subtotal en vivo al agregar un ítem"
```

---

### Task 7: Lista de materiales en PDF (sin precios)

**Files:**
- Modify: `Gemfile` (`prawn`, `prawn-table`; `pdf-reader` in the test group), `Gemfile.lock`
- Create: `app/services/exports/material_list_pdf.rb`
- Modify: `app/controllers/constructors/projects/material_lists_controller.rb:40-53` (`format.pdf`)
- Modify: `app/components/constructors/projects/materials/list_detail_component.html.erb:20-24`, `app/views/constructors/projects/material_lists/show.html.erb:54-57`, `app/views/constructors/projects/material_lists/show.html+mobile.erb`
- Test: `spec/services/exports/material_list_pdf_spec.rb` (new), `spec/requests/constructors/projects/material_list_exports_spec.rb` (new)

**Interfaces:**
- Produces: `Exports::MaterialListPdf.new(list)` with `#render → String` (binary PDF), `#filename → String`, `#rows → Array<Array<String>>` (public, for tests).

- [ ] **Step 1: Add the gems**

```ruby
# Gemfile (general group, next to the other export/document gems)
# PDF de listas de materiales para pedir cotización (Exports::MaterialListPdf).
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2"

# group :test
gem "pdf-reader", "~> 2.12"
```

Run: `bundle install --prefer-local` (prawn 2.5.0, prawn-table 0.2.2 and pdf-reader 2.13.0 are already installed on the machine).
Expected: `Bundle complete!`

- [ ] **Step 2: Write the failing tests**

```ruby
# spec/services/exports/material_list_pdf_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Exports::MaterialListPdf do
  let(:project) { create(:project, name: "Torre Aurora") }
  let(:stage) { create(:project_stage, project: project, name: "Replanteo") }
  let(:list) { create(:material_list, project: project, project_stage: stage, name: "Hierros") }

  before do
    list.material_items.destroy_all
    create(:material_item, material_list: list, name: "Hierro 8 mm", quantity: 12.5, unit: "barra",
                           estimated_cost_cents: 987_654, notes: "Entregar en obra")
  end

  def pdf_text(pdf)
    PDF::Reader.new(StringIO.new(pdf.render)).pages.map(&:text).join("\n")
  end

  it "es un PDF con obra, etapa, código e ítems — y SIN precios" do
    pdf = described_class.new(list)
    text = pdf_text(pdf)

    expect(pdf.render).to start_with("%PDF")
    expect(text).to include("Torre Aurora", "Replanteo", list.code, "Hierros", "Hierro 8 mm", "12,5", "barra", "Entregar en obra")
    expect(text).not_to include("9.876", "9876", "Precio", "Subtotal")
  end

  it "no explota con caracteres fuera de Windows-1252 (emoji, otros alfabetos)" do
    list.material_items.first.update!(name: "Cemento 🧱 水泥", notes: "ñandú m³ ½")

    expect { described_class.new(list).render }.not_to raise_error
    expect(pdf_text(described_class.new(list))).to include("ñandú m³ ½")
  end

  it "arma el nombre de archivo con el código y el nombre de la lista" do
    expect(described_class.new(list).filename).to eq("materiales-#{list.code.downcase}-hierros.pdf")
  end
end
```

```ruby
# spec/requests/constructors/projects/material_list_exports_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exportar lista de materiales", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let(:list) { create(:material_list, project: project, author: constructor) }

  before { sign_in(constructor) }

  it "descarga el PDF" do
    get constructors_project_material_list_path(project, list, format: :pdf)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("attachment", ".pdf")
    expect(response.body).to start_with("%PDF")
  end

  it "el CSV sigue trayendo los precios estimados" do
    get constructors_project_material_list_path(project, list, format: :csv)

    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include("Precio unit. est. (ARS)")
  end

  it "el detalle ofrece PDF y Excel" do
    get constructors_project_material_list_path(project, list), headers: { "Turbo-Frame" => "drawer" }

    expect(response.body).to include(constructors_project_material_list_path(project, list, format: :pdf))
    expect(response.body).to include(constructors_project_material_list_path(project, list, format: :csv))
  end
end
```

(Check the `material_lists` and `material_items` factory traits/attributes, and adjust `author`/`project_stage` if they are named differently.)

- [ ] **Step 3: Run tests to verify they fail**

Run: `bundle exec rspec spec/services/exports/material_list_pdf_spec.rb spec/requests/constructors/projects/material_list_exports_spec.rb`
Expected: FAIL (`uninitialized constant Exports::MaterialListPdf`, and `format.pdf` → 406/UnknownFormat).

- [ ] **Step 4: Implement the service**

```ruby
# app/services/exports/material_list_pdf.rb
# frozen_string_literal: true

require "prawn"
require "prawn/table"

module Exports
  # PDF de una lista de materiales para pedir cotización a un corralón o
  # proveedor: SIN los precios estimados, que son de uso interno (feedback
  # 29/09). El CSV/Excel los sigue trayendo.
  #
  #   pdf = Exports::MaterialListPdf.new(list)
  #   send_data pdf.render, filename: pdf.filename, type: "application/pdf"
  class MaterialListPdf
    HEADERS = [ "#", "Material", "Descripción", "Cantidad", "Unidad", "Notas" ].freeze

    def initialize(list)
      @list = list
    end

    def render
      pdf = Prawn::Document.new(page_size: "A4", margin: 36, info: { Title: safe(title) })
      header(pdf)
      items_table(pdf)
      pdf.number_pages "Página <page> de <total>", at: [ pdf.bounds.right - 150, -6 ], width: 150,
                                                    align: :right, size: 8, color: "999999"
      pdf.render
    end

    def filename
      slug = [ list.code.presence, list.name.to_s.parameterize.presence ].compact.join("-").downcase
      "materiales-#{slug.presence || list.id}.pdf"
    end

    # Una fila por ítem, en el orden en que se cargaron.
    def rows
      items.each_with_index.map do |item, index|
        [ (index + 1).to_s, safe(item.name), safe(item.description), quantity(item.quantity), safe(item.unit), safe(item.notes) ]
      end
    end

    private

    attr_reader :list

    def items
      @items ||= list.material_items.order(:created_at).to_a
    end

    def title
      "#{list.code} #{list.name}".strip
    end

    def header(pdf)
      pdf.text "Lista de materiales", size: 9, color: "777777"
      pdf.text safe(title), size: 18, style: :bold
      pdf.move_down 4
      meta = [
        "Obra: #{list.project.name}",
        ("Etapa: #{list.project_stage.name}" if list.project_stage),
        "Fecha: #{Date.current.strftime('%d/%m/%Y')}"
      ].compact.join("   ·   ")
      pdf.text safe(meta), size: 9, color: "555555"
      if list.notes.present?
        pdf.move_down 6
        pdf.text safe(list.notes), size: 9
      end
      pdf.move_down 12
    end

    def items_table(pdf)
      if items.empty?
        pdf.text "La lista no tiene ítems.", size: 10, color: "777777"
        return
      end

      pdf.table([ HEADERS ] + rows, header: true, width: pdf.bounds.width,
                cell_style: { size: 9, padding: [ 4, 6 ], border_color: "DDDDDD" },
                column_widths: { 0 => 26, 3 => 62, 4 => 56 }) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = "F2F2F2"
        table.column(0).align = :right
        table.column(3).align = :right
      end
    end

    # 12.5 → "12,5"; 10.0 → "10".
    def quantity(value)
      ActiveSupport::NumberHelper.number_to_rounded(value.to_d, precision: 2, strip_insignificant_zeros: true,
                                                                 delimiter: ".", separator: ",")
    end

    # Las fuentes base de Prawn (Helvetica) son Windows-1252: cubren todo el
    # castellano (ñ, tildes, ², ³, ½) pero no emojis ni otros alfabetos, y
    # con esos caracteres Prawn levanta una excepción. Se cambian por "?".
    def safe(text)
      text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end
  end
end
```

- [ ] **Step 5: Implement the controller and the buttons**

`material_lists_controller.rb#show`, inside `respond_to`, after `format.csv`:

```ruby
      # PDF para pedir cotización: sin precios (ver Exports::MaterialListPdf).
      format.pdf do
        pdf = Exports::MaterialListPdf.new(@material_list)
        send_data pdf.render, filename: pdf.filename, type: "application/pdf", disposition: "attachment"
      end
```

`list_detail_component.html.erb:20-24`, replace the "Exportar" button (and its comment) with:

```erb
      <%# Descargas directas (data-turbo=false: el drawer vive dentro del frame
          global y Turbo las interceptaba). El PDF es para pedir cotización,
          sin precios; el Excel (CSV) los trae. %>
      <%= render Qb::MenuComponent.new(label: 'Descargar', icon: :download, variant: :ghost, size: :sm,
            aria_label: 'Descargar la lista', items: [
              { label: 'PDF para cotizar (sin precios)', icon: :doc,
                href: constructors_project_material_list_path(project, list, format: :pdf), data: { turbo: false } },
              { label: 'Excel (CSV, con precios)', icon: :grid,
                href: constructors_project_material_list_path(project, list, format: :csv), data: { turbo: false } }
            ]) %>
```

`material_lists/show.html.erb:54-57`: same menu, with `project` → `@project` and `list` → `@material_list`.

`show.html+mobile.erb`: before the last block of buttons (around line 119), add:

```erb
<div style="padding:0 16px 12px;">
  <%= link_to constructors_project_material_list_path(@project, ml, format: :pdf),
        data: { turbo: false }, class: "m-btn m-btn--secondary m-btn--md",
        style: "width:100%;text-decoration:none;" do %>
    Descargar PDF para cotizar
  <% end %>
</div>
```

(Check the local variable name in the mobile view: `ml` per line 20.)

- [ ] **Step 6: Run tests to verify they pass**

Run: `bundle exec rspec spec/services/exports/material_list_pdf_spec.rb spec/requests/constructors/projects/material_list_exports_spec.rb spec/requests/constructors/projects/material_items_spec.rb spec/components/qb/menu_component_spec.rb`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add Gemfile Gemfile.lock app/services/exports/material_list_pdf.rb \
  app/controllers/constructors/projects/material_lists_controller.rb \
  app/components/constructors/projects/materials/list_detail_component.html.erb \
  app/views/constructors/projects/material_lists/ spec/services/exports/material_list_pdf_spec.rb \
  spec/requests/constructors/projects/material_list_exports_spec.rb
git commit -m "feat(materiales): descarga en PDF para cotizar (sin precios)"
```

---

### Task 8: Moneda del presupuesto — modelo, cotización y comparaciones

**Files:**
- Create: `db/migrate/<timestamp>_add_budget_currency_to_projects.rb`
- Create: `app/services/money/usd_ars_rate.rb`
- Modify: `app/models/current.rb`, `app/models/project.rb`
- Modify: `app/decorators/project_decorator.rb:126-137` (`budget`, + `budget_label`, `budget_ars_hint`)
- Modify: `app/helpers/quickbuild_helper.rb` (`qb_fmt_ars`, `qb_fmt_ars_full`, `qb_fmt_cents` with currency; `qb_currency_symbol`)
- Modify: `app/services/dashboard_kpis.rb:23` (`sum_int(:budget)`)
- Modify: `app/services/constructors/projects/stage_template_service.rb:194-199`, `stage_template_capture_service.rb:112-119` (`budget_ars_cents`)
- Modify: `app/components/constructors/projects/overview/attention_card_component.rb:64-73` (`budget_ars_cents`)
- Modify: `app/controllers/constructors/projects_controller.rb` (`projects_csv`: `decorated.budget`)
- Test: `spec/services/money/usd_ars_rate_spec.rb` (new), `spec/models/project_spec.rb`, `spec/decorators/project_decorator_spec.rb`, `spec/helpers/quickbuild_helper_spec.rb`, `spec/services/dashboard_kpis_spec.rb`, `spec/services/constructors/projects/stage_template_service_spec.rb`

**Interfaces:**
- Produces:
  - column `projects.budget_currency` (string, `"ARS"` default, not null); `Project::BUDGET_CURRENCIES = %w[ARS USD]`
  - `Project#budget_in_usd? → Boolean`, `Project#budget_ars_cents → Integer | nil`
  - `Money::UsdArsRate.current → BigDecimal | nil` (oficial venta, memoized per request in `Current`)
  - `ProjectDecorator#budget → Integer` (ARS cents, 0 if missing or no rate), `#budget_label(mode: :auto) → String | nil` (original currency), `#budget_ars_hint → String | nil` ("≈ $ 54.3M al dólar oficial", USD only)
  - `qb_fmt_cents(cents, currency: "ARS", mode: :auto)`, `qb_fmt_ars(amount, mode:, symbol: "$")`, `qb_fmt_ars_full(amount, symbol: "$")`, `qb_currency_symbol(currency) → "$" | "US$"`

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/services/money/usd_ars_rate_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Money::UsdArsRate do
  before { Current.reset }
  after { Current.reset }

  def stub_rates(hash)
    allow_any_instance_of(External::ExchangeRatesFetcher).to receive(:call).and_return(hash)
  end

  it "usa el dólar oficial venta" do
    stub_rates(oficial: { compra: 1045, venta: 1085 }, blue: { compra: 1200, venta: 1250 }, stale: false)
    expect(described_class.current).to eq(BigDecimal("1085"))
  end

  it "cae a la compra si no hay venta" do
    stub_rates(oficial: { compra: 1045 }, blue: {}, stale: true)
    expect(described_class.current).to eq(BigDecimal("1045"))
  end

  it "es nil sin cotización (dolarapi caído y sin último valor conocido)" do
    stub_rates(oficial: {}, blue: {}, stale: true)
    expect(described_class.current).to be_nil
  end

  it "se pide una sola vez por request" do
    fetcher = instance_double(External::ExchangeRatesFetcher, call: { oficial: { venta: 1085 } })
    allow(External::ExchangeRatesFetcher).to receive(:new).and_return(fetcher)

    2.times { described_class.current }

    expect(fetcher).to have_received(:call).once
  end
end
```

`spec/models/project_spec.rb`:

```ruby
  describe "#budget_ars_cents" do
    it "en pesos es el mismo presupuesto" do
      expect(build(:project, budget_cents: 500_00, budget_currency: "ARS").budget_ars_cents).to eq(500_00)
    end

    it "en dólares lo convierte al oficial del día" do
      allow(Money::UsdArsRate).to receive(:current).and_return(BigDecimal("1085"))
      expect(build(:project, budget_cents: 50_000_00, budget_currency: "USD").budget_ars_cents).to eq(54_250_000_00)
    end

    it "en dólares y sin cotización es nil (no se inventa un número)" do
      allow(Money::UsdArsRate).to receive(:current).and_return(nil)
      expect(build(:project, budget_cents: 50_000_00, budget_currency: "USD").budget_ars_cents).to be_nil
    end
  end

  it "sólo acepta ARS o USD" do
    expect(build(:project, budget_currency: "EUR")).not_to be_valid
  end
```

`spec/decorators/project_decorator_spec.rb`:

```ruby
  describe "presupuesto en dólares" do
    let(:project) { create(:project, budget_cents: 10_000_00, budget_currency: "USD") }

    it "compara contra lo gastado en pesos convertidos" do
      allow(Money::UsdArsRate).to receive(:current).and_return(BigDecimal("1000"))
      create(:project_stage, project: project, spent_cents: 12_000_000_00) # $ 12M > US$ 10k × 1000 × 1.1
      decorated = ProjectDecorator.new(project.reload)

      expect(decorated.budget).to eq(10_000_000_00)
      expect(decorated.health).to eq(:bad)
      expect(decorated.budget_label).to eq("US$ 10k")
      expect(decorated.budget_ars_hint).to eq("≈ $ 10.0M al dólar oficial")
    end

    it "sin cotización apaga la comparación" do
      allow(Money::UsdArsRate).to receive(:current).and_return(nil)
      create(:project_stage, project: project, spent_cents: 99_000_000_00)
      decorated = ProjectDecorator.new(project.reload)

      expect(decorated.budget).to eq(0)
      expect(decorated.health).not_to eq(:bad)
      expect(decorated.budget_label).to eq("US$ 10k")
      expect(decorated.budget_ars_hint).to be_nil
    end
  end
```

`spec/helpers/quickbuild_helper_spec.rb`:

```ruby
  describe "monedas" do
    it "qb_fmt_cents con USD usa US$" do
      expect(helper.qb_fmt_cents(5_000_000, currency: "USD")).to eq("US$ 50k")
      expect(helper.qb_fmt_cents(5_000_000, currency: "USD", mode: :full)).to eq("US$ 50.000")
    end

    it "en pesos no cambia" do
      expect(helper.qb_fmt_cents(5_000_000)).to eq("$ 50k")
    end

    it "qb_currency_symbol" do
      expect(helper.qb_currency_symbol("USD")).to eq("US$")
      expect(helper.qb_currency_symbol("ARS")).to eq("$")
      expect(helper.qb_currency_symbol(nil)).to eq("$")
    end
  end
```

`spec/services/dashboard_kpis_spec.rb`, add:

```ruby
  it 'suma los presupuestos en pesos (USD convertido)' do
    allow(Money::UsdArsRate).to receive(:current).and_return(BigDecimal("1000"))
    p1 = create(:project, owner: user, budget_cents: 100_000_00)
    p2 = create(:project, owner: user, budget_cents: 1_000_00, budget_currency: "USD")
    result = described_class.new([ p1, p2 ].map { ProjectDecorator.new(_1) }).call
    expect(result[:budget_total_cents]).to eq(100_000_00 + 1_000_000_00)
  end
```

`spec/services/constructors/projects/stage_template_service_spec.rb`: copy the existing `apply_budgets` example (lines ~60-94) into a new one with a USD project (`budget_cents: 10_000_00, budget_currency: "USD"`, rate stubbed at 1000), and expect the stage `budget_cents` to equal `budget_pct` × 10_000_000_00 / 100 (ARS cents).

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/services/money/usd_ars_rate_spec.rb spec/models/project_spec.rb spec/decorators/project_decorator_spec.rb spec/helpers/quickbuild_helper_spec.rb spec/services/dashboard_kpis_spec.rb spec/services/constructors/projects/stage_template_service_spec.rb`
Expected: FAIL (no column, no service, no methods).

- [ ] **Step 3: Migration**

```ruby
# db/migrate/<timestamp>_add_budget_currency_to_projects.rb
class AddBudgetCurrencyToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :budget_currency, :string, null: false, default: "ARS"
  end
end
```

(Use the same `Migration[x.y]` as the newest migration in `db/migrate/`.)

Run: `bin/rails db:migrate && RAILS_ENV=test bin/rails db:migrate`
Expected: `db/schema.rb` gains `t.string "budget_currency", default: "ARS", null: false` in `projects`.

- [ ] **Step 4: Implement the model, rate, decorator, helpers and consumers**

`app/models/current.rb`:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  # Cotización del dólar memoizada por request (Money::UsdArsRate).
  attribute :usd_ars_rate, :usd_ars_rate_loaded

  delegate :user, to: :session, allow_nil: true
end
```

`app/services/money/usd_ars_rate.rb`:

```ruby
# frozen_string_literal: true

module Money
  # Cotización para llevar a pesos los presupuestos cargados en dólares:
  # dólar oficial venta de dolarapi (External::ExchangeRatesFetcher, cacheado
  # 1 h y con último valor conocido si la API falla). Se memoiza por request
  # en Current: un listado con muchas obras pide la cotización una sola vez.
  # nil = no hay cotización; quien convierte apaga la comparación.
  class UsdArsRate
    def self.current
      return Current.usd_ars_rate if Current.usd_ars_rate_loaded

      Current.usd_ars_rate_loaded = true
      Current.usd_ars_rate = fetch
    end

    def self.fetch
      rates = External::ExchangeRatesFetcher.new.call
      value = rates.dig(:oficial, :venta) || rates.dig(:oficial, :compra)
      rate = value.to_s.to_d
      rate.positive? ? rate : nil
    rescue StandardError
      nil
    end
  end
end
```

`app/models/project.rb` (next to the status constants):

```ruby
  # Moneda en que se cargó el presupuesto. Lo gastado siempre está en pesos,
  # así que para comparar se usa #budget_ars_cents (feedback 29/09).
  BUDGET_CURRENCIES = %w[ARS USD].freeze
  validates :budget_currency, inclusion: { in: BUDGET_CURRENCIES }

  def budget_in_usd?
    budget_currency == "USD"
  end

  # Presupuesto en centavos de ARS, para compararlo contra lo gastado. USD se
  # convierte al dólar oficial venta del día; sin cotización devuelve nil y
  # las comparaciones (salud, % usado, sobrecosto) se apagan.
  def budget_ars_cents
    return budget_cents unless budget_in_usd?
    return nil if budget_cents.nil?

    rate = Money::UsdArsRate.current
    rate && (budget_cents * rate).round
  end
```

`quickbuild_helper.rb`:

```ruby
  CURRENCY_SYMBOLS = { "ARS" => "$", "USD" => "US$" }.freeze

  # "$" / "US$" (lo que no se reconoce cae en pesos).
  def qb_currency_symbol(currency)
    CURRENCY_SYMBOLS.fetch(currency.to_s, "$")
  end

  # "$ 2.5M" / "$ 45k" / "$ 800" / "—" (`symbol:` para otras monedas: "US$ 50k")
  def qb_fmt_ars(cents_or_amount, mode: :auto, symbol: "$")
    return "—" if cents_or_amount.nil?
    n = cents_or_amount.to_f
    abs = n.abs
    case mode
    when :compact, :auto
      return "#{symbol} #{(n / 1_000_000.0).round(1)}M" if abs >= 1_000_000
      return "#{symbol} #{(n / 1_000.0).round}k"        if abs >= 1_000
      "#{symbol} #{n.round}"
    when :full
      qb_fmt_ars_full(n, symbol: symbol)
    end
  end

  # "$ 12.345.678" — Argentina formatting with thousands separator
  def qb_fmt_ars_full(amount, symbol: "$")
    return "—" if amount.nil?
    "#{symbol} #{amount.round.to_s.reverse.scan(/\d{1,3}/).join('.').reverse}"
  end

  # Cents → short form in the given currency ("ARS" by default)
  def qb_fmt_cents(cents, currency: "ARS", mode: :auto)
    qb_fmt_ars((cents.to_i / 100.0).round, mode: mode, symbol: qb_currency_symbol(currency))
  end
```

(Update the module's top comment: "Currency lives in ARS (budgets can be USD: see Project#budget_ars_cents)".)

`project_decorator.rb`, replace `budget` (l.126-128) with:

```ruby
  # Presupuesto en centavos de ARS (USD convertido al oficial del día): es el
  # que se compara contra lo gastado, que está en pesos. 0 sin presupuesto o
  # sin cotización — las comparaciones se apagan.
  def budget
    object.budget_ars_cents.to_i
  end

  # El presupuesto en la moneda en que se cargó: "US$ 50k" / "$ 2.5M".
  def budget_label(mode: :auto)
    return nil unless budget_cents.to_i.positive?

    h.qb_fmt_cents(budget_cents, currency: budget_currency, mode: mode)
  end

  # "≈ $ 54.3M al dólar oficial" (sólo USD con cotización disponible).
  def budget_ars_hint
    return nil unless object.budget_in_usd? && budget.positive?

    "≈ #{h.qb_fmt_cents(budget)} al dólar oficial"
  end
```

(Check that `BaseDecorator`/Draper exposes `h`. If it doesn't, use `ApplicationController.helpers`.)

Consumers:
- `dashboard_kpis.rb:23`: `budget_total_cents: sum_int(:budget),` + comment "(en pesos: USD convertido, ver ProjectDecorator#budget)".
- `stage_template_service.rb#resolved_budget_cents`: `total = project.budget_ars_cents.to_i` + comment "(las etapas guardan pesos: una obra en USD se convierte)".
- `stage_template_capture_service.rb#budget_pct_for`: `total = project.budget_ars_cents.to_i`.
- `attention_card_component.rb#overcost`: `budget = @project.budget_ars_cents.to_i`.
- `projects_controller.rb#projects_csv`: `(project.budget_cents.to_i / 100.0).round(2)` → `(decorated.budget / 100.0).round(2)` (the "Presupuesto (ARS)" column now holds pesos for USD projects too).

- [ ] **Step 5: Run tests to verify they pass**

Run: `bundle exec rspec spec/services/money/ spec/models/project_spec.rb spec/decorators/ spec/helpers/ spec/services/dashboard_kpis_spec.rb spec/services/constructors/projects/ spec/components/constructors/ spec/requests/constructors/dashboard_report_spec.rb`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add db/ app/models/ app/services/ app/decorators/project_decorator.rb app/helpers/quickbuild_helper.rb \
  app/components/constructors/projects/overview/attention_card_component.rb \
  app/controllers/constructors/projects_controller.rb spec/
git commit -m "feat(obra): presupuesto en ARS o USD, comparado en pesos al dólar oficial"
```

---

### Task 9: Moneda del presupuesto — formularios y pantallas

**Files:**
- Create: `app/javascript/controllers/qb/currency_symbol_controller.js`
- Modify: `app/controllers/constructors/projects_controller.rb` (`project_params`: `:budget_currency`)
- Modify forms: `app/views/constructors/projects/new.html.erb` (drawer ~l.27-31 and page ~l.98-102), `_form.html.erb` (edit: + Cliente, + Presupuesto), `new.html+mobile.erb:31-38`, `edit.html+mobile.erb:31-38`
- Modify displays: `app/components/constructors/projects/header_component.html.erb:81`, `overview/obra_card_component.rb:68-70`, `list/grid_card_component.html.erb:24`, `dashboard/projects_table_component.html.erb:41-42`, `app/views/constructors/projects/show.html+mobile.erb:84-87`, `_mobile_card.html.erb:31`
- Test: `spec/requests/constructors/projects_spec.rb`, `spec/components/constructors/projects/overview/rail_components_spec.rb`, `spec/components/constructors/projects/list/grid_card_component_spec.rb` (create if missing)

**Interfaces:**
- Consumes (Task 8): `ProjectDecorator#budget_label`, `#budget_ars_hint`, `qb_currency_symbol`, `Project::BUDGET_CURRENCIES`.
- Produces: Stimulus `qb--currency-symbol` (target `select`, action `sync`; rewrites the `.qb-money-currency` spans inside its element).

- [ ] **Step 1: Write the failing tests**

`spec/requests/constructors/projects_spec.rb` (inside "alta de obra"):

```ruby
    it "guarda el presupuesto en dólares" do
      post constructors_projects_path, params: { project: { name: "Obra USD", budget_currency: "USD", budget_pesos: "50.000" } }

      expect(constructor.owned_projects.find_by!(name: "Obra USD"))
        .to have_attributes(budget_currency: "USD", budget_cents: 5_000_000)
    end

    it "el alta ofrece la moneda del presupuesto" do
      get new_constructors_project_path
      expect(response.body).to include('name="project[budget_currency]"', ">USD</option>")
    end
```

and a new `describe "edición de obra"`:

```ruby
  describe "edición de obra" do
    let(:constructor) { create(:user, :constructor) }
    let(:project) { create(:project, owner: constructor, budget_cents: 1_500_000_00) }

    before { sign_in(constructor) }

    it "permite editar cliente, presupuesto y moneda" do
      get edit_constructors_project_path(project), headers: { "Turbo-Frame" => "drawer" }

      expect(response.body).to include('name="project[client]"', 'name="project[budget_pesos]"', 'name="project[budget_currency]"')
    end
  end
```

`rail_components_spec.rb` (ObraCard, next to the example at :82-99):

```ruby
    it "muestra el presupuesto en dólares con su equivalente en pesos" do
      allow(Money::UsdArsRate).to receive(:current).and_return(BigDecimal("1000"))
      project.update!(budget_cents: 50_000_00, budget_currency: "USD")
      render_inline(Constructors::Projects::Overview::ObraCardComponent.new(project: project.decorate))

      expect(page).to have_text("US$ 50.000")
      expect(page).to have_text("≈ $ 50.0M al dólar oficial")
    end
```

(Reuse the `project`/`render_inline` setup of the existing ObraCard example and its constructor signature.)

`grid_card_component_spec.rb` (100× bug):

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::List::GridCardComponent, type: :component do
  it "muestra lo gastado en pesos (antes salía multiplicado por 100)" do
    project = create(:project, budget_cents: 10_000_000_00)
    create(:project_stage, project: project, spent_cents: 1_500_000_00)

    render_inline(described_class.new(project: project.reload))

    expect(page).to have_text("$ 1.5M")
  end
end
```

(The component may need `with_request_url` or a `current_user` stub. Copy the setup from a spec of a similar component.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/constructors/projects_spec.rb spec/components/constructors/projects/overview/rail_components_spec.rb spec/components/constructors/projects/list/grid_card_component_spec.rb`
Expected: FAIL (`budget_currency` is not permitted and not in the forms, the edit form has no budget or client, ObraCard shows "$", the grid shows "$ 150.0M").

- [ ] **Step 3: Implement**

`projects_controller.rb#project_params`: add `:budget_currency` to `permit` (after `:budget_pesos`). Update the comment: "`budget_pesos` es el monto tipeado (es-AR) en la moneda de `budget_currency`, ARS o USD; el nombre quedó de cuando sólo había pesos."

`app/javascript/controllers/qb/currency_symbol_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// El prefijo del campo de monto ("$" / "US$") sigue al selector de moneda que
// tiene al lado (presupuesto de la obra).
const SYMBOLS = { ARS: "$", USD: "US$" }

export default class extends Controller {
  static targets = ["select"]

  sync() {
    const symbol = SYMBOLS[this.selectTarget.value] || "$"
    this.element.querySelectorAll(".qb-money-currency").forEach((el) => { el.textContent = symbol })
  }
}
```

Shared partial `app/views/constructors/projects/_budget_fields.html.erb` (desktop; used by the drawer, the full-page new and `_form`):

```erb
<%# Presupuesto de la obra: moneda (ARS/USD) + monto. En USD se compara contra
    lo gastado al dólar oficial del día (Project#budget_ars_cents).
    Locals: f (form builder). %>
<div class="qb-field" data-controller="qb--currency-symbol">
  <%= f.label :budget_pesos, "Presupuesto estimado", class: "qb-label" %>
  <div style="display:grid;grid-template-columns:96px 1fr;gap:8px;">
    <%= f.select :budget_currency, Project::BUDGET_CURRENCIES.map { |c| [ c, c ] }, {},
          class: "qb-select", "aria-label": "Moneda del presupuesto",
          data: { "qb--currency-symbol-target": "select", action: "qb--currency-symbol#sync" } %>
    <%= render Qb::MoneyFieldComponent.new(form: f, method: :budget_pesos, placeholder: "1.500.000",
          currency: qb_currency_symbol(f.object.budget_currency),
          value: qb_money_input_value(f.object.budget_cents)) %>
  </div>
  <span style="font-size:10.5px;color:var(--color-ink-4);">En dólares se compara contra los gastos al dólar oficial del día.</span>
</div>
```

- `new.html.erb` drawer: replace the "Presupuesto estimado (ARS)" `qb-field` (l.27-31) with `<%= render "constructors/projects/budget_fields", f: f %>`.
- `new.html.erb` full page: replace the `<label>` "Presupuesto estimado (ARS)" (l.98-102) with `<div style="grid-column:1 / -1;"><%= render "constructors/projects/budget_fields", f: f %></div>` (it takes the whole row: it has its own grid).
- `_form.html.erb` (edit): in "Información general" add, after the name, a `qb-field` "Cliente" (`f.text_field :client, placeholder: 'Razón social', class: "qb-input"`). In "Planificación temporal", after the "Estado" select, add `<div style="grid-column:span 2;"><%= render "constructors/projects/budget_fields", f: f %></div>`. Comment: "el presupuesto y el cliente sólo se cargaban en el alta (ObraCard mandaba a editar datos que el form no tenía)".
- Mobile new/edit (both l.31-38), inside "Presupuesto y estado", before the amount:

```erb
    <%= render Qb::Mobile::FormRowComponent.new(
          label: "Moneda", name: "project[budget_currency]", select: true,
          value: @project.budget_currency, options: Project::BUDGET_CURRENCIES.map { |c| [ c, c ] }) %>
```

and on the `FormAmountRowComponent`: `currency: qb_currency_symbol(@project.budget_currency)` and `sub: "En la moneda elegida. En dólares se compara al dólar oficial del día."`.

Displays:
- `header_component.html.erb:81`: `hint: "de #{helpers.qb_fmt_cents(project.budget_cents)}"` → `hint: "de #{project.budget_label || '—'}"`.
- `obra_card_component.rb#budget_label`:

```ruby
  # En la moneda en que se cargó; en USD, con el equivalente en pesos.
  def budget_label
    label = project.budget_label(mode: :full)
    label && [ label, project.budget_ars_hint ].compact.join(" · ")
  end
```

(If `project` might arrive undecorated, wrap it at the component's `initialize`: `project.is_a?(ProjectDecorator) ? project : project.decorate`. Check how it is built today.)
- `grid_card_component.html.erb:24`: `helpers.qb_fmt_ars(project.spent)` → `helpers.qb_fmt_cents(project.spent)`.
- `projects_table_component.html.erb:41-42`: `helpers.qb_fmt_ars(p.spent)` → `helpers.qb_fmt_cents(p.spent)`; `de <%= helpers.qb_fmt_ars(p.budget) %>` → `de <%= p.budget_label || '—' %>`.
- `show.html+mobile.erb:86`: `<%= budget_pct %>% de <%= qb_fmt_cents(p.budget) %>` → `<%= budget_pct %>% de <%= p.budget_label || '—' %>`.
- `_mobile_card.html.erb:31`: `<%= qb_fmt_cents(pd.spent) %> / <%= qb_fmt_cents(pd.budget) %>` → `<%= qb_fmt_cents(pd.spent) %> / <%= pd.budget_label || '—' %>`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/constructors/projects_spec.rb spec/components/constructors/ spec/system/constructors/projects/new_project_wizard_spec.rb spec/system/constructors/projects/project_show_header_spec.rb spec/system/projects_spec.rb spec/requests/constructors/dashboard_spec.rb`
Expected: PASS. If `header_component_spec`/`project_show_header_spec` expected "de $ X" and the factory has no budget, they now show "de —"; adjust only if they assert on the hint.

- [ ] **Step 5: Commit**

```bash
git add app/javascript/controllers/qb/currency_symbol_controller.js app/controllers/constructors/projects_controller.rb \
  app/views/constructors/projects/ app/components/constructors/ spec/
git commit -m "feat(obra): moneda del presupuesto en los forms y en las pantallas; arregla montos ×100"
```

---

### Task 10: Notas de la Bitácora vinculadas a una etapa

**Files:**
- Modify: `app/models/note.rb` (scope `for_project`)
- Modify: `app/helpers/constructors/projects_helper.rb` (+ `stage_select_options(project)`), `app/controllers/constructors/expenses_controller.rb:111-117` (delete the method + `helper_method`), `app/views/constructors/expenses/new.html.erb:42`, `new.html+mobile.erb:30` (`stage_select_options(@project)`)
- Modify: `app/controllers/constructors/notes_controller.rb`
- Modify: `app/components/constructors/projects/overview/logbook_component.{rb,html.erb}`
- Modify: `app/views/constructors/notes/new.html.erb`, `new.html+mobile.erb`
- Modify: `app/services/projects/section_counts.rb:25`
- Modify: `app/assets/tailwind/application.css` (`.qb-composer-stage`)
- Test: `spec/requests/constructors/notes_spec.rb`, `spec/services/projects/section_counts_spec.rb:33`, `spec/models/note_spec.rb`, `spec/components/constructors/projects/overview/rail_components_spec.rb`

**Interfaces:**
- Produces: `Note.for_project(project_or_id)`; helper `stage_select_options(project) → [[label, id], …]` (roots plus sub-stages shown as "  ↳ name"). Task 11 uses both (`Image.for_project` follows the same pattern).

- [ ] **Step 1: Write the failing tests**

`spec/models/note_spec.rb`:

```ruby
  describe ".for_project" do
    it "trae las notas de la obra y de sus etapas, no las de otra obra" do
      project = create(:project)
      stage = create(:project_stage, project: project)
      own = create(:note, noteable: project)
      of_stage = create(:note, noteable: stage)
      create(:note, noteable: create(:project_stage))

      expect(described_class.for_project(project)).to contain_exactly(own, of_stage)
    end
  end
```

`spec/requests/constructors/notes_spec.rb`:

```ruby
  describe "notas de la Bitácora vinculadas a una etapa" do
    let!(:stage) { create(:project_stage, project: project, name: "Replanteo") }

    it "la nota rápida se guarda en la etapa elegida y vuelve a la Bitácora" do
      post constructors_project_notes_path(project),
           params: { note: { body: "Se replanteó el eje A", stage_id: stage.id } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(stage.notes.last.body).to eq("Se replanteó el eje A")
      expect(response.body).to include('action="refresh"')
    end

    it "en mobile vuelve a la Bitácora, no a la etapa" do
      cookies["qb_mobile_client"] = "1"
      post constructors_project_notes_path(project), params: { note: { body: "x", stage_id: stage.id } }

      expect(response).to redirect_to(constructors_project_notes_path(project))
    end

    it "la Bitácora lista las notas de etapa con el nombre de la etapa" do
      create(:note, noteable: stage, body: "Nota de etapa")
      get constructors_project_notes_path(project)

      expect(response.body).to include("Nota de etapa", "Replanteo")
      expect(response.body).to include('name="note[stage_id]"')
    end

    it "una nota de etapa se puede borrar desde la Bitácora" do
      note = create(:note, noteable: stage)
      delete constructors_project_note_path(project, note)

      expect(Note.exists?(note.id)).to be(false)
      expect(response).to redirect_to(constructors_project_notes_path(project))
    end

    it "no alcanza notas de etapas de otra obra" do
      foreign = create(:note, noteable: create(:project_stage))
      delete constructors_project_note_path(project, foreign)

      expect(response).to have_http_status(:not_found)
      expect(Note.exists?(foreign.id)).to be(true)
    end

    it "una etapa de otra obra no se puede elegir" do
      post constructors_project_notes_path(project), params: { note: { body: "x", stage_id: create(:project_stage).id } }
      expect(response).to have_http_status(:not_found)
    end
  end
```

(Adjust `project` and the sign-in to that file's `let`s. If the app turns `ActiveRecord::RecordNotFound` into an exception instead of a 404 in request specs, use `expect { … }.to raise_error(ActiveRecord::RecordNotFound)` the same way other specs in the repo do.)

`section_counts_spec.rb:33`: the `notes` example must count project + stage notes. Create one of each and expect 2.

`rail_components_spec.rb` (Logbook): with a stage in the project, the composer renders `select[name='note[stage_id]']` with the option "Toda la obra" and the stage name.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/models/note_spec.rb spec/requests/constructors/notes_spec.rb spec/services/projects/section_counts_spec.rb spec/components/constructors/projects/overview/rail_components_spec.rb`
Expected: FAIL

- [ ] **Step 3: Implement**

`note.rb`:

```ruby
  # Notas de la obra y de todas sus etapas: la Bitácora muestra las dos.
  scope :for_project, ->(project) {
    project_id = project.respond_to?(:id) ? project.id : project
    where(noteable_type: "Project", noteable_id: project_id)
      .or(where(noteable_type: "ProjectStage", noteable_id: ProjectStage.where(project_id: project_id).select(:id)))
  }
```

`section_counts.rb:25`: `notes: ->(id) { Note.for_project(id) },` + update the class comment ("bitácora = notas de la obra y de sus etapas").

`projects_helper.rb`, move the method from `ExpensesController` here:

```ruby
  # Opciones de un selector "Etapa": raíces en orden de WBS con sus sub-etapas
  # indentadas debajo. Lo usan gastos, notas de la Bitácora y fotos. Quien
  # recibe el id lo busca en project.project_stages, así que un id ajeno no pasa.
  def stage_select_options(project)
    project.project_stages.root.order(:position, :name).includes(:sub_stages).flat_map do |root|
      [ [ root.name, root.id ] ] +
        root.sub_stages.sort_by { |s| [ s.position.to_i, s.name.to_s ] }.map { |s| [ "  ↳ #{s.name}", s.id ] }
    end
  end
```

Delete `stage_select_options` and its `helper_method` from `ExpensesController`. In `expenses/new.html.erb:42` and `new.html+mobile.erb:30`: `stage_select_options` → `stage_select_options(@project)`.

`notes_controller.rb`:
- `index`: `@notes = Note.for_project(@project.object).recent_first.includes(:author, :noteable).to_a` + comment "obra + etapas".
- `set_noteable`:

```ruby
    # Ruta de etapa (/stages/:stage_id/notes): nota del detalle de la etapa.
    # Ruta de la obra con note[stage_id]: nota de la Bitácora vinculada a una
    # etapa — se guarda en la etapa pero se vuelve a la Bitácora (sin @stage).
    def set_noteable
      if params[:stage_id].present?
        @stage = @project.project_stages.find(params[:stage_id])
        @noteable = @stage
      elsif (stage_id = params.dig(:note, :stage_id)).present?
        @noteable = @project.project_stages.find(stage_id)
      else
        @noteable = @project
      end
    end
```

- `create`: the condition `if mobile_variant? || @noteable.is_a?(ProjectStage)` → `if mobile_variant? || @stage`. Update the comment above it ("Ruta de etapa: … Bitácora (aunque la nota sea de una etapa): refresh").
- `set_note` else branch: `@note = Note.for_project(@project).find(params[:id])` + comment "desde la Bitácora también se borran notas de etapa".
- `redirect_path`: `if @stage` → stage path (tab notas), else notes index.

`logbook_component.rb`:
- `note_entries`: meta with the stage:

```ruby
      stage = note.noteable if note.noteable_type == "ProjectStage"
      meta = [ (stage && "Etapa #{stage.name}"), author_label(note.author), "hace #{time_ago_in_words(note.created_at)}" ].compact.join(" · ")
```

- new method:

```ruby
  # Etapas para vincular la nota rápida (vacío = sin selector).
  def stage_options
    @stage_options ||= helpers.stage_select_options(project)
  end
```

`logbook_component.html.erb`, inside `.qb-composer-foot`, before `<span style="flex:1;"></span>`:

```erb
          <% if stage_options.any? %>
            <%= select_tag "note[stage_id]", options_for_select([ [ "Toda la obra", "" ] ] + stage_options),
                  class: "qb-select qb-composer-stage", "aria-label": "Etapa de la nota" %>
          <% end %>
```

`application.css` (next to `.qb-composer-*`):

```css
.qb-composer-stage { height: 26px; max-width: 200px; padding: 0 24px 0 8px; font-size: 11.5px; }
```

`notes/new.html.erb` (drawer), after the body field, only when it comes from the obra:

```erb
        <% if @stage.nil? && (options = stage_select_options(@project)).any? %>
          <div class="qb-field">
            <%= label_tag "note_stage_id", "Etapa (opcional)", class: "qb-label" %>
            <%= select_tag "note[stage_id]", options_for_select([ [ "— Toda la obra —", "" ] ] + options, params.dig(:note, :stage_id)),
                  id: "note_stage_id", class: "qb-select" %>
          </div>
        <% end %>
```

`notes/new.html+mobile.erb`, same idea inside its form group:

```erb
    <% if @stage.nil? && (options = stage_select_options(@project)).any? %>
      <%= render Qb::Mobile::FormRowComponent.new(label: "Etapa", name: "note[stage_id]", select: true,
            value: params.dig(:note, :stage_id), options: [ [ "— Toda la obra —", "" ] ] + options) %>
    <% end %>
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/models/note_spec.rb spec/requests/constructors/notes_spec.rb spec/services/projects/section_counts_spec.rb spec/components/constructors/projects/ spec/requests/constructors/expenses_spec.rb spec/system/constructors/projects/adding_a_note_to_project_spec.rb spec/system/constructors/projects/adding_a_note_to_stage_spec.rb spec/policies/note_policy_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/models/note.rb app/helpers/constructors/projects_helper.rb app/controllers/constructors/ \
  app/views/constructors/expenses/ app/views/constructors/notes/ app/components/constructors/projects/overview/ \
  app/services/projects/section_counts.rb app/assets/tailwind/application.css spec/
git commit -m "feat(bitácora): notas vinculadas a una etapa desde la Bitácora"
```

---

### Task 11: Fotos vinculadas a etapas (+ tab Fotos)

Found while researching: on desktop the Fotos page was unreachable (only the mobile tile linked to it), and deleting a stage photo crashed (`@image.purge` on an ActiveRecord model).

**Files:**
- Modify: `app/models/image.rb` (scope `for_project`)
- Modify: `app/controllers/constructors/projects/images_controller.rb`
- Modify: `app/controllers/constructors/projects/stages/images_controller.rb:85` (`purge` → `destroy`)
- Modify: `app/views/constructors/projects/images/index.html.erb`, `index.html+mobile.erb`
- Modify: `app/views/constructors/projects/_section_tabs.html.erb` (tab Fotos), `app/components/qb/layout/navigation.rb` (PROJECT_NAV + `project_url`), `app/services/projects/section_counts.rb` (`photos`)
- Modify: `app/decorators/project_decorator.rb` (`attachments_count` → `Image.for_project`)
- Test: `spec/requests/constructors/projects/images_spec.rb` (new), `spec/models/image_spec.rb`, `spec/services/projects/section_counts_spec.rb`

**Interfaces:**
- Consumes (Task 10): helper `stage_select_options(project)`.
- Produces: `Image.for_project(project_or_id)`; `@current_qb_project_sub = :photos`; tab `:photos`.

- [ ] **Step 1: Write the failing tests**

```ruby
# spec/requests/constructors/projects/images_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Fotos de la obra", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let!(:stage) { create(:project_stage, project: project, name: "Replanteo") }
  let(:photo) { fixture_file_upload("photo.png", "image/png") }

  before { sign_in(constructor) }

  it "sube una foto vinculada a una etapa" do
    post constructors_project_images_path(project), params: { image: { files: [ photo ], stage_id: stage.id } }

    expect(stage.images.count).to eq(1)
    expect(response).to redirect_to(constructors_project_images_path(project))
  end

  it "sin etapa, la foto es de la obra" do
    post constructors_project_images_path(project), params: { image: { files: [ photo ] } }
    expect(project.images.count).to eq(1)
  end

  it "la galería muestra fotos de la obra y de las etapas, con la etapa, y filtra por etapa" do
    create(:image, imageable: project, title: "fachada.png")
    create(:image, imageable: stage, title: "estacas.png")

    get constructors_project_images_path(project)
    expect(response.body).to include("fachada.png", "estacas.png", "Replanteo", 'name="image[stage_id]"')

    get constructors_project_images_path(project, stage: stage.id)
    expect(response.body).to include("estacas.png")
    expect(response.body).not_to include("fachada.png")

    get constructors_project_images_path(project, stage: "none")
    expect(response.body).to include("fachada.png")
    expect(response.body).not_to include("estacas.png")
  end

  it "borra una foto de etapa desde la galería de la obra" do
    image = create(:image, imageable: stage)
    delete constructors_project_image_path(project, image)

    expect(Image.exists?(image.id)).to be(false)
  end

  it "no alcanza fotos de otra obra" do
    foreign = create(:image, imageable: create(:project_stage))
    delete constructors_project_image_path(project, foreign)

    expect(response).to have_http_status(:not_found)
    expect(Image.exists?(foreign.id)).to be(true)
  end

  it "borrar una foto desde el detalle de la etapa ya no explota" do
    image = create(:image, imageable: stage)
    delete constructors_project_stage_image_path(project, stage, image)

    expect(Image.exists?(image.id)).to be(false)
  end

  it "la obra tiene tab Fotos" do
    get constructors_project_path(project)
    expect(response.body).to include(constructors_project_images_path(project), "Fotos")
  end
end
```

(Check that `spec/fixtures/files/photo.png` exists; the `images` factory uses it. Same 404 note as Task 10.)

`spec/models/image_spec.rb`: `.for_project` (same shape as the Note test in Task 10).
`section_counts_spec.rb`: `counts[:photos]` counts project photos plus stage photos.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/requests/constructors/projects/images_spec.rb spec/models/image_spec.rb spec/services/projects/section_counts_spec.rb`
Expected: FAIL

- [ ] **Step 3: Implement**

`image.rb`:

```ruby
  # Fotos de la obra y de todas sus etapas: la galería de la obra muestra las dos.
  scope :for_project, ->(project) {
    project_id = project.respond_to?(:id) ? project.id : project
    where(imageable_type: "Project", imageable_id: project_id)
      .or(where(imageable_type: "ProjectStage", imageable_id: ProjectStage.where(project_id: project_id).select(:id)))
  }
```

`section_counts.rb`: add `photos: ->(id) { Image.for_project(id) },` to `SCOPES` (before `notes`).

`stages/images_controller.rb:85`: `@image.purge` → `@image.destroy` + comment "Image es un modelo AR (purge es de los attachments): destroy borra la fila y el archivo".

`projects/images_controller.rb`:

```ruby
class Constructors::Projects::ImagesController < Constructors::BaseController
  before_action :find_project!

  # Galería de la obra: fotos de la obra y de sus etapas, filtrables por etapa
  # (all | none = sólo de la obra | id de etapa).
  def index
    authorize @project, :show?
    @current_qb_section = :projects
    @current_qb_project = @project.decorate
    @current_qb_project_sub = :photos

    @stage_filter = params[:stage].to_s.presence || "all"
    scope = Image.for_project(@project).includes(:imageable, file_attachment: :blob).order(created_at: :desc)
    scope = scope.where(imageable_type: "Project") if @stage_filter == "none"
    scope = scope.where(imageable_type: "ProjectStage", imageable_id: @stage_filter.to_i) if @stage_filter.match?(/\A\d+\z/)
    @images = scope
  end

  def create
    # Subir fotos de obra es contenido (editor+), no edición de la obra.
    authorize @project, :manage_content?
    # Vincular a una etapa es opcional; se busca dentro de la obra.
    target = stage_id.present? ? @project.project_stages.find(stage_id) : @project
    # … existing body unchanged, except `@project.images.build` → `target.images.build`
  end

  def destroy
    authorize @project, :manage_content?
    # Desde la galería también se borran fotos de etapa (siempre de esta obra).
    image = Image.for_project(@project).find(params[:id])
    image.destroy
    redirect_to constructors_project_images_path(@project), notice: "Imagen eliminada."
  end

  private

  def image_params
    params.fetch(:image, {}).permit(:title, :description, files: [])
  end

  def stage_id
    params.dig(:image, :stage_id)
  end
end
```

Tabs and nav:
- `_section_tabs.html.erb`, between `:docs` and `:logbook`: `{ value: :photos, label: 'Fotos', icon: :image, count: counts[:photos], href: constructors_project_images_path(project) },`. Update the header comment to list `:photos`.
- `navigation.rb`: `PROJECT_NAV` gets `{ key: :photos, label: "Fotos", icon: :image },` after `:docs`. `project_url` gets `when :photos then helpers.constructors_project_images_path(project)`.
- `project_decorator.rb#attachments_count`: `Image.for_project(object).count`.

Desktop `images/index.html.erb`:
- `section_tabs … current: :photos`.
- Header strip: eyebrow `· Fotos`, title "Fotos de obra", subtitle without "← Volver a Documentos" (now it is its own tab).
- Upload form: before the `FileFieldComponent`, when `can_upload && (options = stage_select_options(@project)).any?`:

```erb
      <%= select_tag "image[stage_id]", options_for_select([ [ "Toda la obra", "" ] ] + options),
            class: "qb-select", "aria-label": "Etapa de las fotos", style: "height:28px;width:auto;max-width:200px;font-size:12px;" %>
```

- Filter toolbar under the header (same pattern as `expenses/index.html.erb:49-58`), only when the project has stages:

```erb
<% stage_rows = @project.project_stages.order(:position, :name).pluck(:id, :name) %>
<% if stage_rows.any? %>
  <div style="display:flex;align-items:center;gap:8px;padding:10px 20px;border-bottom:1px solid var(--color-line);background:var(--color-bg-raised);">
    <%= render Qb::FilterChipComponent.new(label: 'Etapa', param: :stage, value: @stage_filter,
          options: [ [ 'all', 'Todas' ], [ 'none', 'Sólo de la obra' ] ] + stage_rows.map { |id, name| [ id.to_s, name ] },
          base_path: constructors_project_images_path(@project)) %>
  </div>
<% end %>
```

- Each card: under the date line, the stage. Change the meta line to:

```erb
            <div style="font-size:10px;color:var(--color-ink-4);margin-top:1px;">
              <%= qb_fmt_date_short(image.created_at) %> · <%= image.imageable_type == "ProjectStage" ? image.imageable.name : "Obra" %>
            </div>
```

- Empty state with a filter applied: "No hay fotos con este filtro." (otherwise keep the current text, fixing the "arriba a la derecha" hint if it changes).

Mobile `images/index.html+mobile.erb`:
- In the upload card, before the file input, when there are stages: a native `<select name="image[stage_id]" class="m-frow-input">` with "Toda la obra" plus `stage_select_options(@project)` (`options_for_select`).
- The file input stays `accept="image/*"` **without** `capture`: with `capture` the phone goes straight to the camera and you can't pick from the gallery. Without it, iOS/Android offer both.
- Filter pills (copy `expenses/index.html+mobile.erb:20-30`) with `stage` instead of `category`: "Todas", "Obra", and one per stage.
- In each tile, under the date: the stage name or "Obra".

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/requests/constructors/projects/images_spec.rb spec/models/image_spec.rb spec/services/projects/section_counts_spec.rb spec/requests/constructors/row_actions_spec.rb spec/components/qb/layout/ spec/requests/constructors/projects_spec.rb spec/components/constructors/projects/header_component_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/models/image.rb app/controllers/constructors/projects/ app/views/constructors/projects/ \
  app/components/qb/layout/navigation.rb app/services/projects/section_counts.rb app/decorators/project_decorator.rb spec/
git commit -m "feat(fotos): tab Fotos, fotos vinculadas a etapas con filtro; arregla borrar foto de etapa"
```

---

### Task 12: Menú de cuenta en el topbar (Perfil / Cerrar sesión)

**Files:**
- Modify: `app/components/qb/layout/topbar_component.html.erb:50-60`
- Modify: `app/components/qb/layout/sidebar_component.rb:72-75` (style → constant `ACCOUNT_MENU_ROW_STYLE`, shared)
- Test: `spec/components/qb/layout/topbar_component_spec.rb` (new)

**Interfaces:**
- Produces: `Qb::Layout::SidebarComponent::ACCOUNT_MENU_ROW_STYLE` (String).

- [ ] **Step 1: Write the failing test**

```ruby
# spec/components/qb/layout/topbar_component_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qb::Layout::TopbarComponent, type: :component do
  let(:user) { create(:user, :constructor, email: "miguel@obra.com") }

  it "el avatar abre un menú con Perfil y Cerrar sesión" do
    with_request_url "/constructors" do
      render_inline(described_class.new(user: user))
    end

    expect(page).to have_button(type: "button", "aria-label": "Menú de cuenta")
    expect(page).to have_link("Perfil", href: "/registration/edit", visible: :all)
    expect(page).to have_css("form[action='/session'] input[name='_method'][value='delete']", visible: :all)
    expect(page).to have_button("Cerrar sesión", visible: :all)
  end
end
```

(Check the real paths of `edit_registration_path` / `session_path` in `config/routes.rb:22-23`, and whether `TopbarComponent` needs more arguments, by looking at how `layouts/constructor.html.erb:62-67` renders it.)

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/components/qb/layout/topbar_component_spec.rb`
Expected: FAIL (the user block is not a button and has no menu).

- [ ] **Step 3: Implement**

`sidebar_component.rb`: turn `account_menu_row_style` into a constant and keep the method delegating to it:

```ruby
  # Fila del menú de cuenta (Perfil / Cerrar sesión). Compartido con el
  # menú del avatar del topbar.
  ACCOUNT_MENU_ROW_STYLE = "width:100%;display:flex;align-items:center;gap:8px;padding:7px 10px;background:transparent;border:none;border-radius:4px;color:var(--color-ink);font-size:12px;font-weight:500;cursor:pointer;text-decoration:none;text-align:left;"

  def account_menu_row_style
    ACCOUNT_MENU_ROW_STYLE
  end
```

`topbar_component.html.erb`, replace the `<% if user %> … <% end %>` block (l.50-60) with:

```erb
    <% if user %>
      <%# Menú de cuenta (feedback 29/09: cerrar sesión a la derecha, al tocar
          el usuario). Mismo patrón qb--dropdown que la campana de alertas. %>
      <div data-controller="qb--dropdown" style="position:relative;padding-left:8px;margin-left:4px;border-left:1px solid var(--color-line);">
        <button type="button" aria-label="Menú de cuenta" aria-haspopup="menu"
                data-action="click->qb--dropdown#toggle"
                style="display:flex;align-items:center;gap:8px;padding:2px 4px;background:transparent;border:none;border-radius:5px;color:var(--color-ink);cursor:pointer;text-align:left;">
          <%= render Qb::AvatarComponent.new(name: user_short_name, size: 26) %>
          <span style="line-height:1.1;">
            <span style="display:block;font-size:12px;font-weight:500;"><%= user_short_name %></span>
            <% if user_role %>
              <span style="display:block;font-size:10px;color:var(--color-ink-3);"><%= user_role %></span>
            <% end %>
          </span>
          <%= render Qb::IconComponent.new(name: :'chevron-down', size: 12, style: 'color:var(--color-ink-3);') %>
        </button>
        <div data-qb--dropdown-target="menu" class="hidden" role="menu"
             style="display:none;position:absolute;top:36px;right:0;z-index:41;min-width:200px;padding:4px;background:var(--color-bg);border:1px solid var(--color-line);border-radius:6px;box-shadow:0 8px 20px -4px rgba(0,0,0,0.25);">
          <div style="padding:6px 10px 8px;font-size:11px;color:var(--color-ink-3);border-bottom:1px solid var(--color-line);margin-bottom:4px;overflow:hidden;text-overflow:ellipsis;"><%= user.email %></div>
          <%= link_to helpers.edit_registration_path, role: "menuitem", style: Qb::Layout::SidebarComponent::ACCOUNT_MENU_ROW_STYLE do %>
            <%= render Qb::IconComponent.new(name: :settings, size: 13, style: 'color:var(--color-ink-3);flex-shrink:0;') %>
            <span>Perfil</span>
          <% end %>
          <%= button_to helpers.session_path, method: :delete, role: "menuitem", form: { style: 'margin:0;' },
                        style: Qb::Layout::SidebarComponent::ACCOUNT_MENU_ROW_STYLE do %>
            <%= render Qb::IconComponent.new(name: :'arrow-right', size: 13, style: 'color:var(--color-ink-3);flex-shrink:0;') %>
            <span>Cerrar sesión</span>
          <% end %>
        </div>
      </div>
    <% end %>
```

(Check that `:'chevron-down'` exists in `Qb::IconComponent`. If not, use the one the sidebar switcher uses. The `box-shadow` matches the bell panel; if the bell uses a token, use the same one.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/components/qb/layout/ spec/system/constructors/redesign/layout_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/components/qb/layout/ spec/components/qb/layout/topbar_component_spec.rb
git commit -m "feat(layout): menú de cuenta en el avatar del topbar con Perfil y Cerrar sesión"
```

---

### Task 13: CLAUDE.md, verificación completa y QA visual

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update CLAUDE.md** (short, in the existing sections):
  - Drawer: "Un drawer cuyo panel contiene un `<form>` (que no sea `button_to`) no se cierra con clic afuera ni Escape (solo Guardar/Cancelar/×); una vista de consulta con un form embebido lo marca `data-drawer-dismissable`."
  - Maps: "El mapa se ve siempre; mostrarlo no ubica la obra: las coordenadas se escriben sólo si ya estaba ubicada, si se eligió una sugerencia, si se arrastró el mapa o con «Usar mi ubicación actual» (`placed` en `project_map_controller.js`). El stub `__gmMoveMap` dispara `dragstart`+`idle`."
  - Money: "`projects.budget_currency` (ARS/USD). Comparar contra lo gastado SIEMPRE con `ProjectDecorator#budget` / `Project#budget_ars_cents` (USD × oficial venta, `Money::UsdArsRate`, memo por request en `Current`); mostrar con `budget_label`. `qb_fmt_cents(cents, currency:)`. Component/decorator specs con obras USD stubean `Money::UsdArsRate.current`."
  - Exports: "PDF de lista de materiales con Prawn (`Exports::MaterialListPdf`, sin precios; fuentes base Windows-1252, los caracteres fuera de rango se cambian por `?`)."
  - Project sections: "tab Fotos (`images#index`, obra + etapas, filtro por etapa); `Note.for_project`/`Image.for_project` = obra + sus etapas (Bitácora y Fotos las usan)."
  - Statuses: "`planned` se muestra «Inicio»; el alta sólo ofrece `Project::CREATE_STATUSES`."
  - Known rough edges: "Gastos cargados en USD (form mobile) se suman como pesos en `SpendSummary`/`SpendTotals` (pendiente)."

- [ ] **Step 2: Full suite**

Run: `bundle exec rspec`
Expected: 0 failures. Compare against the baseline of 971 examples, 0 failures, 7 pending.

- [ ] **Step 3: Lint and security**

Run: `bundle exec rubocop $(git diff --name-only main...HEAD -- '*.rb' | tr '\n' ' ')` → no offenses (`-a` for the safe ones).
Run: `bin/brakeman --no-pager` → no new warnings.
Run: `bin/importmap audit` → OK.

- [ ] **Step 4: Visual QA** (skill `run` / Playwright, `bin/dev`):
  - Drawer "Nuevo proyecto": click outside → nudge, does not close; × closes.
  - Map visible when the drawer opens; "Usar mi ubicación actual".
  - Stage create with Responsable/Presupuesto; edit → card updated without a reload.
  - List detail: live subtotal; "Descargar" menu (PDF and Excel); open the PDF.
  - USD budget in the form (the prefix switches to US$), header, Datos de la obra.
  - Bitácora with the stage selector; Fotos tab with the filter.
  - Topbar avatar → menu with Cerrar sesión.
  - Night theme on each of the above.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md con lo nuevo del feedback 29/09"
```
