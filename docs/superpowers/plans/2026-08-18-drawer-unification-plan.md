# Unificación de modales en drawer lateral — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every centered modal (`qb--modal`) and every full-page-only create/edit form under `Constructors::` with ONE right-anchored Turbo Frame drawer (`Qb::DrawerComponent` + a single global `"drawer"` turbo-frame), desktop only, with a professional slide-in animation and a consistent header/body/footer chrome.

**Architecture:**
A single `<turbo-frame id="drawer">` lives once in `layouts/constructor.html.erb`, wrapped in a fixed backdrop+panel shell controlled by an enhanced `qb--drawer` Stimulus controller. Views populate it via `content_for(:drawer) { render(Qb::DrawerComponent.new(...)) { ... } }` on `turbo_frame_request?`; the same action keeps its existing full-page fallback (added where missing) for direct URL access. Frame-empty-closes / frame-content-opens is the single open/closed rule — no more per-view boolean flags. `project_modal` and `stage_detail` disappear as frame names; stage viewing and editing become one panel. `qb--modal` is deleted once nothing references it.

**Tech Stack:** Rails 8, Hotwire (Turbo Frames + Streams incl. the Turbo 8 native `turbo_stream.refresh` and one custom `redirect` stream action), Stimulus, ViewComponent, Tailwind (QB OS design tokens only).

**Spec:** `docs/superpowers/specs/2026-08-18-drawer-unification-design.md` (sections 1–4 referenced throughout below).

## Global Constraints

- **Desktop only.** Never touch any `*.html+mobile.erb` file, `layouts/mobile.html.erb`, or anything gated by `mobile_variant?`/`request.variant.include?(:mobile)`. Every controller change that adds a `format.turbo_stream` branch MUST guard mobile out explicitly (`if request.variant.include?(:mobile)` → fall back to plain redirect/render), because Turbo Drive negotiates `turbo_stream` for ALL intercepted form submissions, mobile included — this is not optional, it is how `notes_controller#create` already protects itself today.
- **All 18 call sites, no exceptions**, except the one explicitly documented "Invitar miembro" case (stays inline, reskinned only — no route/controller change, since `project_memberships` has no `:new` action and adding one is out of scope).
- **QB OS tokens only** in every new/touched line: `var(--color-*)`, `var(--font-mono)`, `var(--radius*)`. No raw Tailwind palette classes, no `bg-white`, no `shadow-sm`.
- **Money fields**: preserve `permitted.key?(:x_pesos)` (not `.present?`) everywhere a budget/amount field is touched, so an emptied field can still clear the stored cents.
- **Delete-with-confirm links keep `turbo_frame: '_top'`** everywhere — destroying something should always leave the drawer/page entirely. Only CREATE/UPDATE form submissions and pure "cancel/close" actions are touched by this migration.
- **Every drawer-opening trigger gets `data: { turbo_frame: "drawer", action: "click->qb--drawer#open" }`** (not just `turbo_frame:`) — the click opens the panel immediately (slide-in starts right away) while the frame's content streams in behind it; this is the single biggest perceived-professionalism win and must be applied consistently, not just on the two call sites that already had it.
- **No focus trap.** Documented scope cut (see spec §2) — Escape + backdrop-click close, focus moves to the panel on open, that's it.

---

## Task 1: CSS foundation for the drawer

**Files:**
- Modify: `app/assets/tailwind/application.css`

**Interfaces:**
- Produces classes every later task depends on: `.qb-drawer-shell`, `.qb-drawer-open`, `.qb-drawer-no-transition`, `.qb-drawer-backdrop`, `.qb-drawer-panel` (reads `--qb-drawer-width` custom property), `.qb-drawer-header`, `.qb-drawer-header-main`, `.qb-drawer-eyebrow`, `.qb-drawer-title`, `.qb-drawer-subtitle`, `.qb-drawer-close`, `.qb-drawer-body`, `.qb-drawer-footer`.

- [ ] **Step 1: Append the drawer CSS block**

Add this new block at the very end of `app/assets/tailwind/application.css` (after the existing final `@layer components { ... }` block that ends at line 943), as its own new `@layer components` block:

```css
@layer components {
  /* ─── Drawer lateral global (Qb::DrawerComponent + layouts/constructor) ───
     El frame #drawer vive una sola vez en el layout; es display:contents para
     no interferir con el flex del shell — el panel visual real es el div raíz
     que renderiza Qb::DrawerComponent (el único que carga ancho/transform). */
  .qb-drawer-shell {
    position: fixed; inset: 0; z-index: 70;
    display: flex; justify-content: flex-end;
    opacity: 0; pointer-events: none;
    transition: opacity .18s ease-out;
  }
  .qb-drawer-shell.qb-drawer-open { opacity: 1; pointer-events: auto; }
  .qb-drawer-shell.qb-drawer-no-transition,
  .qb-drawer-shell.qb-drawer-no-transition .qb-drawer-panel { transition: none !important; }

  .qb-drawer-backdrop {
    position: absolute; inset: 0;
    background: color-mix(in oklab, var(--color-ink) 45%, transparent);
  }

  turbo-frame#drawer { display: contents; }

  .qb-drawer-panel {
    position: relative;
    height: 100vh;
    width: var(--qb-drawer-width, 560px);
    max-width: 100vw;
    background: var(--color-bg);
    border-left: 1px solid var(--color-line);
    box-shadow: -8px 0 24px -8px rgba(0,0,0,.25);
    display: flex; flex-direction: column;
    transform: translateX(100%);
    transition: transform .18s ease-out;
    outline: none;
  }
  .qb-drawer-shell.qb-drawer-open .qb-drawer-panel { transform: translateX(0); }

  .qb-drawer-header {
    flex: 0 0 auto; padding: 16px 20px; border-bottom: 1px solid var(--color-line);
    display: flex; align-items: flex-start; gap: 12px;
  }
  .qb-drawer-header-main { flex: 1; min-width: 0; }
  .qb-drawer-eyebrow {
    font-family: var(--font-mono); font-size: 11px; text-transform: uppercase;
    letter-spacing: .8px; color: var(--color-ink-3);
  }
  .qb-drawer-title { margin: 3px 0 0; font-size: 18px; font-weight: 600; letter-spacing: -.3px; color: var(--color-ink); }
  .qb-drawer-subtitle { margin-top: 6px; font-size: 12px; color: var(--color-ink-3); display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
  .qb-drawer-close {
    flex: 0 0 auto; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center;
    border: none; background: transparent; color: var(--color-ink-3); border-radius: var(--radius-sm); cursor: pointer;
  }
  .qb-drawer-close:hover { background: var(--color-bg-sunken); color: var(--color-ink); }

  .qb-drawer-body { flex: 1; overflow: auto; padding: 18px 20px; }
  .qb-drawer-footer {
    flex: 0 0 auto; padding: 12px 20px; border-top: 1px solid var(--color-line);
    display: flex; align-items: center; justify-content: flex-end; gap: 8px;
    background: var(--color-bg-raised);
  }

  turbo-frame#drawer[busy] .qb-drawer-body,
  turbo-frame#drawer[busy] .qb-drawer-footer { opacity: .5; pointer-events: none; }

  @media (prefers-reduced-motion: reduce) {
    .qb-drawer-shell, .qb-drawer-panel { transition-duration: .01ms !important; }
    .qb-drawer-panel { transform: none !important; }
  }
}
```

- [ ] **Step 2: Verify the asset compiles**

Run: `bin/rails tailwindcss:build` (or start `bin/dev` and confirm no Tailwind build error in the log).

- [ ] **Step 3: Commit**

```bash
git add app/assets/tailwind/application.css
git commit -m "feat(drawer): agrega CSS del panel lateral unificado"
```

---

## Task 2: `qb--drawer` Stimulus controller — frame-driven + click-driven modes

**Files:**
- Modify: `app/javascript/controllers/qb/drawer_controller.js`

**Interfaces:**
- Produces: `open()`, `close()`, `backdrop(event)`, `keydown(event)` actions; targets `dialog`, `panel`, `frame` (frame optional — see below).
- Consumes: CSS classes from Task 1 (`.qb-drawer-open`, `.qb-drawer-no-transition`).

- [ ] **Step 1: Replace the controller**

Two modes coexist: **frame-driven** (the one global instance in the layout, Task 5) declares a `frame` target wrapping `turbo-frame#drawer`; content-presence after `turbo:frame-load` decides open/closed. **Click-driven** (the one inline exception — "Invitar miembro", Task 18) has no `frame` target; a trigger calls `#open` and the panel calls `#close` directly, same as the old `qb--modal` controller.

Replace the full contents of `app/javascript/controllers/qb/drawer_controller.js` with:

```js
import { Controller } from "@hotwired/stimulus"

// Right-anchored slide-over drawer. Two modes:
//   - Frame-driven (the global instance in layouts/constructor.html.erb):
//     declares a `frame` target wrapping the "drawer" turbo-frame; content
//     presence after any turbo:frame-load decides open/closed, so no view
//     needs its own open-on-connect flag or closest("turbo-frame#...") check.
//   - Click-driven (local, self-contained instances — e.g. "Invitar
//     miembro", which has no #new route to be frame-scoped against): no
//     `frame` target; a trigger calls #open, the panel calls #close.
export default class extends Controller {
  static targets = ["dialog", "panel", "frame"]

  connect() {
    if (this.hasFrameTarget) {
      this.onFrameLoad = this.onFrameLoad.bind(this)
      this.frameTarget.addEventListener("turbo:frame-load", this.onFrameLoad)
      this._setOpen(this._frameHasContent(), { animate: false })
    } else {
      this._setOpen(false, { animate: false })
    }
  }

  disconnect() {
    if (this.hasFrameTarget) this.frameTarget.removeEventListener("turbo:frame-load", this.onFrameLoad)
  }

  onFrameLoad() {
    this._setOpen(this._frameHasContent())
  }

  open() { this._setOpen(true) }

  // Cierre disparado por el botón × / backdrop / Escape: vacía el frame para
  // que la próxima apertura pida contenido fresco en vez de reusar el último
  // estado (ej: "Cancelar" no debe dejar la próxima apertura mostrando el
  // formulario a medio llenar de la vez anterior).
  close() {
    this._setOpen(false)
    if (this.hasFrameTarget) {
      this.frameTarget.innerHTML = ""
      this.frameTarget.removeAttribute("src")
    }
  }

  backdrop(event) {
    if (this.hasPanelTarget && this.panelTarget.contains(event.target)) return
    this.close()
  }

  keydown(event) {
    if (event.key === "Escape" && this.dialogTarget.classList.contains("qb-drawer-open")) {
      event.preventDefault()
      this.close()
    }
  }

  _frameHasContent() {
    return this.hasFrameTarget && this.frameTarget.innerHTML.trim().length > 0
  }

  _setOpen(open, { animate = true } = {}) {
    if (!this.hasDialogTarget) return
    if (!animate) this.dialogTarget.classList.add("qb-drawer-no-transition")
    this.dialogTarget.classList.toggle("qb-drawer-open", open)
    this.dialogTarget.toggleAttribute("aria-hidden", !open)
    document.body.style.overflow = open ? "hidden" : ""
    if (open && this.hasPanelTarget) {
      requestAnimationFrame(() => this.panelTarget.focus())
    }
    if (!animate) {
      requestAnimationFrame(() => this.dialogTarget.classList.remove("qb-drawer-no-transition"))
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/javascript/controllers/qb/drawer_controller.js
git commit -m "feat(drawer): controller soporta modo frame-driven y click-driven"
```

(Nothing to run yet — this controller isn't wired into any markup until Task 5. Rubocop/rspec verification happens at the end, Task 22.)

---

## Task 3: Custom `redirect` Turbo Stream action

**Files:**
- Create: `app/javascript/turbo_stream_actions.js`
- Modify: `app/javascript/application.js`
- Modify: `config/importmap.rb`

**Interfaces:**
- Produces: client-side `Turbo.StreamActions.redirect`, invoked by any server response containing `<turbo-stream action="redirect" target="URL">`. Server side, `turbo_stream.action(:redirect, url)` (native `Turbo::Streams::TagBuilder#action`, no new Ruby helper needed) generates that tag.
- Used by: Task 14 (project create — the ONE true cross-page-navigation exception; every other call site in this plan uses either the native `redirect_to`-followed-as-a-frame-request behavior or Turbo 8's native `turbo_stream.refresh`).

- [ ] **Step 1: Create the client-side action file**

```js
// app/javascript/turbo_stream_actions.js
//
// Custom Turbo Stream action for the ONE case in the drawer unification that
// needs a real full-page Turbo.visit instead of an in-place frame patch:
// creating a brand new project from the global "+ Nuevo proyecto" trigger.
// Every other drawer close/patch in this app is handled by either a plain
// redirect_to (followed as a frame-scoped request by Turbo) or the native
// turbo_stream.refresh action — this one is reserved for "abandon the current
// page/sidebar context entirely, go to a brand new page".
Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.getAttribute("target"))
}
```

- [ ] **Step 2: Pin it in the importmap**

In `config/importmap.rb`, add a new pin line right after `pin "pwa"`:

```ruby
pin "application"
pin "pwa"
pin "turbo_stream_actions"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
```

- [ ] **Step 3: Import it in application.js**

Replace the contents of `app/javascript/application.js`:

```js
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "turbo_stream_actions"
import "controllers"
import "pwa"
```

- [ ] **Step 4: Verify it loads with no console error**

Run: `bin/dev`, open any constructor page in a browser, confirm no JS console error and that `window.Turbo.StreamActions.redirect` is a function (check via devtools console).

- [ ] **Step 5: Commit**

```bash
git add app/javascript/turbo_stream_actions.js app/javascript/application.js config/importmap.rb
git commit -m "feat(drawer): registra la turbo-stream action custom 'redirect'"
```

---

## Task 4: `Qb::DrawerComponent`

**Files:**
- Create: `app/components/qb/drawer_component.rb`
- Create: `app/components/qb/drawer_component.html.erb`
- Test: `spec/components/qb/drawer_component_spec.rb`

**Interfaces:**
- Produces: `Qb::DrawerComponent.new(eyebrow: nil, title: nil, subtitle: nil, size: :lg)`, slots `custom_header` (override the whole header) and `footer` (optional sticky footer bar). Renders a `.qb-drawer-panel` root div carrying `data-qb--drawer-target="panel"` and `--qb-drawer-width` inline — this is the element every later task renders **inside** the `"drawer"` turbo-frame (never wraps the frame itself, that's the layout's job in Task 5).
- Consumes: `Qb::IconComponent` (`:x` icon, already used everywhere else in this codebase).

- [ ] **Step 1: Write the component class**

```ruby
# frozen_string_literal: true

# The single chrome every drawer-hosted view renders inside the "drawer"
# turbo-frame: fixed header (eyebrow + title + optional subtitle + close),
# scrollable body (the block content), optional fixed footer. The outer
# backdrop/positioning shell lives once in layouts/constructor.html.erb
# (Task 5) — this component only renders what goes *inside* the frame, so
# swapping content between views never touches the shell.
class Qb::DrawerComponent < ViewComponent::Base
  renders_one :custom_header
  renders_one :footer

  SIZES = { md: "480px", lg: "560px", xl: "880px" }.freeze

  def initialize(eyebrow: nil, title: nil, subtitle: nil, size: :lg)
    @eyebrow = eyebrow
    @title = title
    @subtitle = subtitle
    @width = SIZES.fetch(size)
  end
end
```

- [ ] **Step 2: Write the template**

```erb
<div class="qb-drawer-panel" data-qb--drawer-target="panel" tabindex="-1" style="--qb-drawer-width: <%= @width %>;">
  <% if custom_header? %>
    <%= custom_header %>
  <% else %>
    <div class="qb-drawer-header">
      <div class="qb-drawer-header-main">
        <% if @eyebrow.present? %><div class="qb-drawer-eyebrow"><%= @eyebrow %></div><% end %>
        <% if @title.present? %><h2 class="qb-drawer-title"><%= @title %></h2><% end %>
        <% if @subtitle.present? %><div class="qb-drawer-subtitle"><%= @subtitle %></div><% end %>
      </div>
      <button type="button" class="qb-drawer-close" data-action="click->qb--drawer#close" aria-label="Cerrar">
        <%= render Qb::IconComponent.new(name: :x, size: 16) %>
      </button>
    </div>
  <% end %>

  <div class="qb-drawer-body">
    <%= content %>
  </div>

  <% if footer? %>
    <div class="qb-drawer-footer"><%= footer %></div>
  <% end %>
</div>
```

- [ ] **Step 3: Write the component spec**

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qb::DrawerComponent, type: :component do
  it "renders eyebrow, title and subtitle in the default header" do
    render_inline(described_class.new(eyebrow: "PRJ-001 · Planificación", title: "Nueva etapa", subtitle: "Etapa raíz")) { "cuerpo" }

    expect(page).to have_css(".qb-drawer-eyebrow", text: "PRJ-001 · Planificación")
    expect(page).to have_css(".qb-drawer-title", text: "Nueva etapa")
    expect(page).to have_css(".qb-drawer-subtitle", text: "Etapa raíz")
    expect(page).to have_css(".qb-drawer-body", text: "cuerpo")
    expect(page).to have_css("button.qb-drawer-close")
  end

  it "supports a custom header slot instead of the default one" do
    render_inline(described_class.new) do |c|
      c.with_custom_header { "<div class=\"my-header\">Custom</div>".html_safe }
      "cuerpo"
    end

    expect(page).to have_css(".my-header", text: "Custom")
    expect(page).to have_no_css(".qb-drawer-eyebrow")
  end

  it "renders an optional sticky footer" do
    render_inline(described_class.new(title: "X")) do |c|
      c.with_footer { "Acciones" }
      "cuerpo"
    end

    expect(page).to have_css(".qb-drawer-footer", text: "Acciones")
  end

  it "omits the footer bar entirely when no footer slot is given" do
    render_inline(described_class.new(title: "X")) { "cuerpo" }

    expect(page).to have_no_css(".qb-drawer-footer")
  end

  it "sets the panel width from the size option" do
    render_inline(described_class.new(title: "X", size: :md)) { "cuerpo" }
    expect(page).to have_css(".qb-drawer-panel[style*='480px']")
  end
end
```

- [ ] **Step 4: Run the spec**

Run: `bundle exec rspec spec/components/qb/drawer_component_spec.rb`
Expected: 5 examples, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/components/qb/drawer_component.rb app/components/qb/drawer_component.html.erb spec/components/qb/drawer_component_spec.rb
git commit -m "feat(drawer): agrega Qb::DrawerComponent"
```

---

## Task 5: Global drawer frame in the layout + sidebar trigger + ⌘N

**Files:**
- Modify: `app/views/layouts/constructor.html.erb`
- Modify: `app/components/qb/layout/sidebar_component.html.erb`
- Modify: `app/javascript/controllers/qb/keyboard_controller.js`

**Interfaces:**
- Produces: the ONE `<turbo-frame id="drawer">` reachable from any constructor page. Every later task's `content_for(:drawer) { ... }` renders into it via `yield(:drawer)`.

- [ ] **Step 1: Add the drawer shell to the layout**

In `app/views/layouts/constructor.html.erb`, insert the drawer shell right before the closing `Qb::Layout::CmdPaletteComponent`/`Qb::Layout::TweaksPanelComponent` block (currently lines 100-101), replacing:

```erb
    <%= render Qb::Layout::CmdPaletteComponent.new %>
    <%= render Qb::Layout::TweaksPanelComponent.new %>
  </body>
```

with:

```erb
    <%# Panel lateral único: reemplaza a project_modal + stage_detail. Vive acá
        (no en cada vista) para que triggers globales como "+ Nuevo proyecto"
        del sidebar funcionen sin importar en qué pantalla esté el usuario.
        Las vistas nunca declaran su propio <turbo-frame id="drawer">: sólo
        proveen contenido con content_for(:drawer), o el layout terminaría
        emitiendo un id duplicado. %>
    <div data-controller="qb--drawer">
      <div class="qb-drawer-shell" data-qb--drawer-target="dialog"
           data-action="click->qb--drawer#backdrop keydown@window->qb--drawer#keydown">
        <div class="qb-drawer-backdrop"></div>
        <%= turbo_frame_tag "drawer", data: { "qb--drawer-target": "frame" } do %>
          <%= yield :drawer %>
        <% end %>
      </div>
    </div>

    <%= render Qb::Layout::CmdPaletteComponent.new %>
    <%= render Qb::Layout::TweaksPanelComponent.new %>
  </body>
```

- [ ] **Step 2: Wire the sidebar's "Nuevo proyecto" trigger**

In `app/components/qb/layout/sidebar_component.html.erb`, replace the New project CTA link (currently):

```erb
    <%= link_to new_project_url, style: 'width:100%;height:32px;display:flex;align-items:center;justify-content:flex-start;gap:8px;padding:0 10px;background:var(--color-accent);color:var(--color-accent-ink);border:none;border-radius:5px;cursor:pointer;font-size:12px;font-weight:600;text-decoration:none;' do %>
```

with:

```erb
    <%= link_to new_project_url, data: { turbo_frame: "drawer", action: "click->qb--drawer#open" }, style: 'width:100%;height:32px;display:flex;align-items:center;justify-content:flex-start;gap:8px;padding:0 10px;background:var(--color-accent);color:var(--color-accent-ink);border:none;border-radius:5px;cursor:pointer;font-size:12px;font-weight:600;text-decoration:none;' do %>
```

(`new_project_url` already resolves to `new_constructors_project_path` — unchanged, only the `data:` attribute is added.)

- [ ] **Step 3: Make ⌘N open the drawer instead of navigating**

Replace the full contents of `app/javascript/controllers/qb/keyboard_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Global ⌘K / ⌘N shortcuts. ⌘K dispatches qb:open on the command palette.
// ⌘N used to Turbo.visit /constructors/projects/new as a full-page
// navigation; now that project creation lives in the unified drawer, it
// clicks the sidebar's own "Nuevo proyecto" trigger instead, so the exact
// same frame-scoped, animated-open path fires regardless of whether the
// user typed ⌘N or clicked the button.
export default class extends Controller {
  connect() {
    this.handler = this.onKey.bind(this)
    window.addEventListener("keydown", this.handler)
  }

  disconnect() {
    window.removeEventListener("keydown", this.handler)
  }

  onKey(event) {
    const mod = event.metaKey || event.ctrlKey
    if (!mod) return

    const key = event.key.toLowerCase()
    if (key === "k") {
      event.preventDefault()
      const palette = document.querySelector("[data-controller~='qb--cmd-palette']")
      if (palette) palette.dispatchEvent(new CustomEvent("qb:open"))
    } else if (key === "n") {
      const active = document.activeElement
      const tag = (active?.tagName || "").toLowerCase()
      if (tag === "input" || tag === "textarea" || (active?.isContentEditable)) return
      event.preventDefault()
      document.querySelector("#qb-sidebar-new-project")?.click()
    }
  }
}
```

- [ ] **Step 4: Give the sidebar trigger the id ⌘N clicks**

In `app/components/qb/layout/sidebar_component.html.erb`, add `id: "qb-sidebar-new-project"` to the same `link_to` from Step 2:

```erb
    <%= link_to new_project_url, id: "qb-sidebar-new-project", data: { turbo_frame: "drawer", action: "click->qb--drawer#open" }, style: 'width:100%;height:32px;display:flex;align-items:center;justify-content:flex-start;gap:8px;padding:0 10px;background:var(--color-accent);color:var(--color-accent-ink);border:none;border-radius:5px;cursor:pointer;font-size:12px;font-weight:600;text-decoration:none;' do %>
```

- [ ] **Step 5: Manual smoke check**

Run `bin/dev`, sign in as a constructor, load any constructor page, press ⌘N (or Ctrl+N). Expected: the drawer slides in from the right with an empty/loading state, then the "Crear una obra" form appears once Task 14 exists (until then it will 404 — that's expected, this task only wires the shell and trigger). Confirm no duplicate-id console warning and that the drawer stays closed on pages that don't set `content_for(:drawer)`.

- [ ] **Step 6: Commit**

```bash
git add app/views/layouts/constructor.html.erb app/components/qb/layout/sidebar_component.html.erb app/javascript/controllers/qb/keyboard_controller.js
git commit -m "feat(drawer): monta el frame global en el layout, sidebar y ⌘N lo abren"
```

---

## Task 6: Etapas — crear/editar (drawer)

**Files:**
- Modify: `app/controllers/constructors/projects/stages_controller.rb`
- Modify: `app/views/constructors/projects/stages/new.html.erb`
- Modify: `app/views/constructors/projects/stages/edit.html.erb`
- Modify: `app/components/constructors/projects/stages/stage_form_component.rb`
- Modify: `app/components/constructors/projects/stages/stage_form_component.html.erb`
- Create: `app/views/constructors/projects/stages/_detail_drawer.html.erb`
- Test: `spec/requests/constructors/projects/stages_spec.rb` (create new file if none exists for this; otherwise add to the existing stages request spec)

**Interfaces:**
- Consumes: `Qb::DrawerComponent` (Task 4), `qb--drawer#close` action (Task 2).
- Produces: `StageFormComponent#in_drawer?` (renamed from `in_modal?`) — used by nothing outside this component, safe rename. Produces the `_detail_drawer` partial (`project:`, `stage:`, `sub_stages:` locals) — Task 9's material-list create branch reuses it too, since both need the exact same "wrap the refreshed `StageDetailComponent` in `Qb::DrawerComponent`" response.

- [ ] **Step 0: Create the shared "stage detail, wrapped in the drawer" partial**

A controller action can pass a bare component instance straight to `turbo_stream.update` (this codebase already does exactly that today), but nesting two components — `Qb::DrawerComponent` wrapping `StageDetailComponent` as its block content — needs real ERB block syntax, which controller Ruby doesn't have. A tiny partial gives both `stages_controller#update` (this task) and `material_lists_controller#create` (Task 9) one shared place to do that nesting via `turbo_stream.update(target, partial:, locals:)`, instead of duplicating it or trying to hand-roll `render_in` calls in controller code.

Create `app/views/constructors/projects/stages/_detail_drawer.html.erb`:

```erb
<%= render(Qb::DrawerComponent.new(eyebrow: "#{stage.code} · Planificación", title: stage.name, size: :lg)) do %>
  <%= render Constructors::Projects::Planning::StageDetailComponent.new(
        project: project, stage: stage, sub_stages: sub_stages) %>
<% end %>
```

(`stage` here is expected to already be `.decorate`d by the caller — both this task's `#update` and Task 9's `#create` already decorate it before passing it in.)

- [ ] **Step 1: Rename frame ids in the controller**

In `app/controllers/constructors/projects/stages_controller.rb`, in `#create` (currently lines 54-66), replace:

```ruby
          respond_to do |format|
            format.turbo_stream do
              decorated_stage = @stage.decorate
              render turbo_stream: [
                turbo_stream.update("project_modal", ""),
                turbo_stream.append("planning_stages",
                  Constructors::Projects::Planning::StageCardComponent.new(
                    project: @project.decorate,
                    stage: decorated_stage,
                    sub_stages: @stage.sub_stages.order(:position, :name)
                  ))
              ]
            end
            format.html { redirect_to stages_page_path, notice: "Etapa creada correctamente." }
          end
```

with:

```ruby
          respond_to do |format|
            format.turbo_stream do
              decorated_stage = @stage.decorate
              render turbo_stream: [
                turbo_stream.update("drawer", ""),
                turbo_stream.append("planning_stages",
                  Constructors::Projects::Planning::StageCardComponent.new(
                    project: @project.decorate,
                    stage: decorated_stage,
                    sub_stages: @stage.sub_stages.order(:position, :name)
                  ))
              ]
            end
            format.html { redirect_to stages_page_path, notice: "Etapa creada correctamente." }
          end
```

In `#update` (currently lines 78-92), replace:

```ruby
            format.turbo_stream do
              @stage.reload
              decorated_stage = @stage.decorate
              decorated_project = @project.decorate
              render turbo_stream: [
                turbo_stream.update("project_modal", ""),
                turbo_stream.update("stage_detail",
                  Constructors::Projects::Planning::StageDetailComponent.new(
                    project: decorated_project,
                    stage: decorated_stage,
                    sub_stages: @stage.sub_stages.order(:position, :name)
                  ))
              ]
            end
```

with:

```ruby
            format.turbo_stream do
              @stage.reload
              render turbo_stream: turbo_stream.update("drawer",
                partial: "constructors/projects/stages/detail_drawer",
                locals: {
                  project: @project.decorate,
                  stage: @stage.decorate,
                  sub_stages: @stage.sub_stages.order(:position, :name)
                })
            end
```

(One stream action now instead of two — updating "drawer" once with the fully-wrapped detail view both closes the edit form and shows the refreshed detail in the same motion; there's no separate "close the modal" step anymore because there's no separate modal. Uses the `_detail_drawer` partial from Step 0.)

- [ ] **Step 2: Convert `stages/new.html.erb` to the drawer**

Replace the full contents of `app/views/constructors/projects/stages/new.html.erb`. The frame-request branch becomes (full-page `else` branch — currently lines 34+ — is unchanged, only the frame branch changes):

```erb
<%# Nueva etapa.
    - turbo_frame_request (botón con data-turbo-frame="drawer"): drawer QB OS.
    - full page (acceso directo): shell de secciones QB OS + form centrado. %>
<% if turbo_frame_request? %>
  <% title = @stage.parent_id.present? ? "Nueva sub-etapa" : "Nueva etapa" %>
  <% subtitle = @stage.parent_id.present? ? "de #{@stage.parent&.name}" : @project.decorate.code %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Planificación", title: title, subtitle: subtitle, size: :lg)) do %>
      <%= render Constructors::Projects::Stages::StageFormComponent.new(project: @project, stage: @stage, in_drawer: true) %>
    <% end %>
  <% end %>
<% else %>
  <%= render 'constructors/projects/section_tabs', project: @project, current: :stages %>

  <%# Header strip %>
  <div style="padding:14px 20px;border-bottom:1px solid var(--color-line);display:flex;align-items:flex-end;gap:16px;">
    <div>
      <div style="font-size:10px;font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.7px;color:var(--color-accent);margin-bottom:4px;">Planificación</div>
      <h3 style="margin:0;font-size:15px;font-weight:600;color:var(--color-ink);"><%= @stage.parent_id.present? ? "Nueva sub-etapa" : "Nueva etapa" %></h3>
      <div style="font-size:12px;color:var(--color-ink-3);margin-top:2px;">
        <%= link_to "Ver planificación", constructors_project_stages_path(@project), style: "color:var(--color-accent);text-decoration:none;" %>
      </div>
    </div>
  </div>

  <div style="padding:24px 20px;">
    <div style="max-width:620px;margin:0 auto;">
      <%= render Constructors::Projects::Stages::StageFormComponent.new(project: @project, stage: @stage) %>
    </div>
  </div>
<% end %>
```

- [ ] **Step 3: Convert `stages/edit.html.erb` to the drawer**

Replace the frame-request branch (currently lines 20-54) in `app/views/constructors/projects/stages/edit.html.erb`, keeping the `context_pills` capture block (lines 1-18) and the full-page `else` branch (currently lines 55-79) exactly as they are:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(
          eyebrow: "Planificación · Etapa #{stage.code}",
          title: @stage.name,
          size: :lg
        )) do |d| %>
      <% d.with_custom_header do %>
        <div class="qb-drawer-header">
          <div class="qb-drawer-header-main">
            <div class="qb-drawer-eyebrow">Planificación · Etapa <%= stage.code %></div>
            <h2 class="qb-drawer-title"><%= @stage.name %></h2>
            <div class="qb-drawer-subtitle"><%= context_pills %></div>
          </div>
          <button type="button" class="qb-drawer-close" data-action="click->qb--drawer#close" aria-label="Cerrar">
            <%= render Qb::IconComponent.new(name: :x, size: 16) %>
          </button>
        </div>
      <% end %>
      <%= render Constructors::Projects::Stages::StageFormComponent.new(project: @project, stage: @stage, in_drawer: true) %>
    <% end %>
  <% end %>
<% else %>
```

(The custom header slot is used here instead of the plain `eyebrow:`/`title:`/`subtitle:` options because `context_pills` is pre-rendered markup, not a plain string — the default header only accepts strings via `.to_s`-style interpolation. Everything from `<% else %>` onward stays exactly as it is today.)

- [ ] **Step 4: Rename `in_modal` → `in_drawer` and the frame references in `StageFormComponent`**

In `app/components/constructors/projects/stages/stage_form_component.rb`, replace:

```ruby
        def initialize(project:, stage:, in_modal: false, cancel_href: nil)
          @project = project
          @stage = stage
          @in_modal = in_modal
          @cancel_href = cancel_href
        end

        private

        attr_reader :project, :stage

        def in_modal?
          @in_modal
        end
```

with:

```ruby
        def initialize(project:, stage:, in_drawer: false, cancel_href: nil)
          @project = project
          @stage = stage
          @in_drawer = in_drawer
          @cancel_href = cancel_href
        end

        private

        attr_reader :project, :stage

        def in_drawer?
          @in_drawer
        end
```

In `app/components/constructors/projects/stages/stage_form_component.html.erb`, replace the footer block (currently lines 90-107):

```erb
  <div style="display:flex;align-items:center;gap:8px;margin-top:4px;padding-top:14px;border-top:1px solid var(--color-line);">
    <% if stage.persisted? %>
      <%# _top: dentro de la modal el DELETE tiene que navegar la página entera,
          si no la redirección se cargaría dentro del frame. %>
      <%= render Qb::BtnComponent.new('Eliminar etapa', variant: :danger, size: :sm,
            href: delete_href,
            data: { turbo_method: :delete,
                    turbo_frame: '_top',
                    turbo_confirm: '¿Eliminar la etapa y todas sus sub-etapas?' }) %>
    <% end %>
    <div style="flex:1;"></div>
    <% if in_modal? %>
      <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, size: :md,
            data: { action: 'click->qb--modal#close' }) %>
    <% else %>
      <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, size: :md,
            href: cancel_href, data: { turbo_frame: '_top' }) %>
    <% end %>
    <%= render Qb::BtnComponent.new(submit_label, variant: :primary, size: :md, type: 'submit') %>
  </div>
```

with:

```erb
  <div style="display:flex;align-items:center;gap:8px;margin-top:4px;padding-top:14px;border-top:1px solid var(--color-line);">
    <% if stage.persisted? %>
      <%= render Qb::BtnComponent.new('Eliminar etapa', variant: :danger, size: :sm,
            href: delete_href,
            data: { turbo_method: :delete,
                    turbo_frame: '_top',
                    turbo_confirm: '¿Eliminar la etapa y todas sus sub-etapas?' }) %>
    <% end %>
    <div style="flex:1;"></div>
    <% if in_drawer? %>
      <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, size: :md,
            data: { action: 'click->qb--drawer#close' }) %>
    <% else %>
      <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, size: :md,
            href: cancel_href, data: { turbo_frame: '_top' }) %>
    <% end %>
    <%= render Qb::BtnComponent.new(submit_label, variant: :primary, size: :md, type: 'submit') %>
  </div>
```

- [ ] **Step 5: Write/extend the request spec**

Add to (or create) `spec/requests/constructors/projects/stages_spec.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Projects::Stages drawer", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }

  before { sign_in_as(constructor) }

  it "renders the drawer panel for a turbo-frame request to #new" do
    get new_constructors_project_stage_path(project), headers: { "Turbo-Frame" => "drawer" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="drawer"')
    expect(response.body).to include("qb-drawer-panel")
  end

  it "renders the full-page fallback for a normal request to #new" do
    get new_constructors_project_stage_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nueva etapa")
  end

  it "closes the drawer and appends the new stage card on create" do
    post constructors_project_stages_path(project),
         params: { project_stage: { name: "Fundaciones" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include('turbo-stream action="update" target="drawer"')
    expect(response.body).to include('turbo-stream action="append" target="planning_stages"')
  end
end
```

(If `sign_in_as` isn't the existing helper name used by other request specs in this codebase, check `spec/support/` for the actual sign-in helper and use that instead — every other request spec in `spec/requests/constructors/` already establishes the convention.)

- [ ] **Step 6: Run the specs**

Run: `bundle exec rspec spec/requests/constructors/projects/stages_spec.rb`
Expected: all examples pass.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/constructors/projects/stages_controller.rb app/views/constructors/projects/stages/new.html.erb app/views/constructors/projects/stages/edit.html.erb app/views/constructors/projects/stages/_detail_drawer.html.erb app/components/constructors/projects/stages/stage_form_component.rb app/components/constructors/projects/stages/stage_form_component.html.erb spec/requests/constructors/projects/stages_spec.rb
git commit -m "feat(drawer): migra alta/edición de etapas al drawer unificado"
```

---

## Task 7: Etapas — detalle unificado (viewer + editor, un solo panel)

**Files:**
- Modify: `app/views/constructors/projects/stages/show.html.erb`
- Modify: `app/components/constructors/projects/planning/stage_detail_component.html.erb`
- Modify: `app/components/constructors/projects/planning/gantt_component.html.erb`
- Modify: `app/components/constructors/projects/planning/stage_card_component.html.erb`
- Modify: `app/views/constructors/projects/show.html.erb`

**Interfaces:**
- Produces: `StageDetailComponent` no longer renders its own `<h1>` title (moved to the host's `Qb::DrawerComponent` header) — every caller (this task's `stages/show.html.erb`, `projects/show.html.erb`, and Task 6's `stages_controller#update`) must supply `eyebrow:`/`title:` to the wrapping `Qb::DrawerComponent`.

- [ ] **Step 1: Remove the title from `StageDetailComponent`'s own hero block**

In `app/components/constructors/projects/planning/stage_detail_component.html.erb`, remove the title line from the hero (currently lines 1-17):

```erb
<%# ① IDENTIDAD ────────────────────────────────────────────── %>
<div class="sd-hero">
  <% if stage.object.parent.present? %>
    <%= link_to "← Volver a #{stage.object.parent.name}",
                constructors_project_stage_path(project, stage.object.parent),
                data: { turbo_frame: "drawer" },
                class: "sd-hero-back" %>
  <% end %>
  <div class="sd-hero-top">
    <span class="sd-code-pill"><%= stage.code %></span>
    <%= render Qb::PillComponent.new(tone: status_tone) { stage.status_label } %>
    <% if stage.overdue? %>
      <%= render Qb::PillComponent.new(tone: :bad) { "Atrasada" } %>
    <% end %>
  </div>

  <% if stage.description.present? %>
    <div class="sd-hero-desc"><%= stage.description %></div>
  <% end %>
```

(Two changes: the `<h1>` title block is removed — the title now lives in the drawer header — and `data-turbo-frame: "stage_detail"` becomes `"drawer"`.)

Then rename every remaining `project_modal`/`stage_detail` frame reference in this same file (lines 92, 98, 129, 137, 206, 223, 253, 256) from `project_modal` → `drawer` and from `stage_detail` → `drawer`, and add the optimistic-open action to every one of them per the Global Constraints rule. Concretely:

Line 92 (sub-stage "Agregar" button) — replace:
```erb
              data: { turbo_frame: 'project_modal' }) %>
```
with:
```erb
              data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' }) %>
```

Line 98 (sub-stage row link) — replace:
```erb
                  data: { turbo_frame: 'stage_detail' } do %>
```
with:
```erb
                  data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' } do %>
```

Line 129 ("Nueva lista" button, Materiales tab) — same substitution as line 92.

Line 137 (material list row link) — replace:
```erb
          <%= link_to constructors_project_material_list_path(project, list), class: 'sd-list-row', data: { turbo_frame: 'project_modal' } do %>
```
with:
```erb
          <%= link_to constructors_project_material_list_path(project, list), class: 'sd-list-row', data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' } do %>
```

Line 206 ("Agregar documentos" button, Docs tab) and line 223 ("Agregar imágenes" button, Fotos tab) — same substitution as line 92.

Line 253 ("Editar" footer button) — same substitution as line 92.

Line 256 ("Marcar completada" footer button) — replace:
```erb
            data: { turbo_method: :patch, turbo_frame: 'stage_detail' }) %>
```
with:
```erb
            data: { turbo_method: :patch, turbo_frame: 'drawer' }) %>
```
(no optimistic-open here — the panel is already open when this button is clicked, since it's part of the footer of the currently-open detail view).

- [ ] **Step 2: Replace the Gastos/Notas inline modals with drawer-frame links**

(This step only renames the tab trigger buttons to point at the new frame-driven views from Task 17 — the full tab-content rewrite, including deleting the inline `qb--modal`/`ExpenseModalComponent`/`NoteModalComponent` usage, happens in Task 17 once those new views exist. For now, in this task, only rename any frame references that already exist in these two tabs — there are none today since they're pure inline modals — so **no change is needed here in this task**; skip to Step 3.)

- [ ] **Step 3: Rename `stages/show.html.erb`, and drop the now-redundant embedded frame in the full-page fallback**

Replace the full contents of `app/views/constructors/projects/stages/show.html.erb`:

```erb
<%# Detalle de etapa. Dentro del drawer llega como turbo_frame request → solo
    el contenido del frame, envuelto en el chrome del drawer (header con
    eyebrow/título, cuerpo, sin footer propio — el footer de acciones vive
    dentro de StageDetailComponent). Entrando directo (link del dashboard,
    bookmark) se envuelve en el shell del proyecto y se renderiza como
    contenido plano: el drawer global del layout sigue ahí y "Editar"/las
    sub-etapas lo abren igual como overlay flotante, sin necesitar un frame
    local propio (evita el id duplicado "drawer" en la misma página). %>
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(
          eyebrow: "#{@stage.decorate.code} · Planificación",
          title: @stage.name,
          size: :lg
        )) do %>
      <%= render Constructors::Projects::Planning::StageDetailComponent.new(
            project: @project, stage: @stage, sub_stages: @sub_stages) %>
    <% end %>
  <% end %>
<% else %>
  <div>
    <%= render 'constructors/projects/section_tabs', project: @project, current: :stages %>

    <%# Header strip %>
    <div style="padding:14px 20px;border-bottom:1px solid var(--color-line);display:flex;align-items:flex-end;gap:16px;">
      <div style="flex:1;">
        <div style="font-size:11px;font-family:var(--font-mono);color:var(--color-ink-3);text-transform:uppercase;letter-spacing:0.8px;"><%= @project.decorate.code %> · Etapas</div>
        <h2 style="margin:3px 0 0;font-size:18px;font-weight:600;letter-spacing:-0.3px;"><%= @stage.name %></h2>
        <div style="font-size:12px;color:var(--color-ink-3);margin-top:2px;">
          <%= @sub_stages.size %> <%= @sub_stages.size == 1 ? 'sub-etapa' : 'sub-etapas' %> · <%= @stage.progress.to_i %>% de avance
          <%= link_to '← Volver a etapas', constructors_project_path(@project), style: 'color:var(--color-accent);text-decoration:none;margin-left:8px;' %>
        </div>
      </div>
    </div>

    <div style="padding:16px 20px;">
      <%= render Constructors::Projects::Planning::StageDetailComponent.new(
            project: @project, stage: @stage, sub_stages: @sub_stages) %>
    </div>
  </div>
<% end %>
```

(Dropped: the local `turbo_frame_tag "stage_detail"` wrapper around the component in the `else` branch, and both trailing bare `turbo_frame_tag "project_modal"` placeholders — the global `"drawer"` frame from Task 5's layout already covers this page, and `StageDetailComponent`'s own internal links now target `"drawer"` directly per Step 1, so "Editar"/sub-stage navigation correctly opens the floating panel as an overlay even from this plain fallback page.)

- [ ] **Step 4: Rename frame references in `gantt_component.html.erb`**

In `app/components/constructors/projects/planning/gantt_component.html.erb`, at lines 20, 84 and 97, replace each:
```erb
                  data: { turbo_frame: 'stage_detail', action: 'click->qb--drawer#open' },
```
with:
```erb
                  data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' },
```
(exact quote style — single vs double — may differ slightly per line; match whatever quoting the existing line uses, only the frame name changes).

- [ ] **Step 5: Rename frame references in `stage_card_component.html.erb`**

In `app/components/constructors/projects/planning/stage_card_component.html.erb`:

Line 22 — replace `data: { turbo_frame: "stage_detail", action: "click->qb--drawer#open" },` with `data: { turbo_frame: "drawer", action: "click->qb--drawer#open" },`.

Line 80 — replace `data: { turbo_frame: 'project_modal' })` with `data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' })`.

Line 111 — same substitution as line 80.

- [ ] **Step 6: Rename the reference host in `projects/show.html.erb`**

In `app/views/constructors/projects/show.html.erb`, replace (around line 221):
```erb
        <%= turbo_frame_tag "stage_detail" do %>
```
This whole block is being superseded by the SAME global drawer mechanism — the project's own show page stops rendering its own local drawer shell/frame entirely (Task 5's layout now provides it globally), so this task removes the local dialog/panel markup here too. Replace the drawer host block (the `data-qb--drawer-target="dialog"` fixed-overlay markup wrapping `turbo_frame_tag "stage_detail"`, roughly lines 195-229 per the earlier investigation) with nothing — delete it outright, since the layout's global drawer now serves this page too. Also delete the trailing bare `turbo_frame_tag "project_modal"` (line 229).

Read the current exact markup range first (`sed -n '190,230p' app/views/constructors/projects/show.html.erb`) before deleting, to confirm the exact start/end lines in case they've shifted, then remove the entire local drawer host block (the outer `data-controller="qb--drawer"` wrapper, its backdrop `div`, and the `turbo_frame_tag "stage_detail"`/bare `turbo_frame_tag "project_modal"` inside/after it) and leave everything else on the page untouched. The stage cards on this page already link with `data-turbo-frame: "stage_detail"` per Step 5/`stage_card_component.html.erb` — after that rename lands, they'll correctly target the layout's global `"drawer"` frame instead, with no page-local frame needed.

- [ ] **Step 7: Manual smoke check**

Run `bin/dev`. From a project's show page: click a stage card → drawer slides in with the detail. Click "Editar" from inside it → same panel swaps to the edit form (no second overlay, no flash of blank page). Save → panel shows the refreshed detail. Click a sub-stage row → panel content swaps to that sub-stage. Press Escape → panel closes. Then visit a stage's URL directly (e.g. paste `/constructors/projects/1/stages/3` in a new tab) → full-page fallback renders; click "Editar" there too → the SAME floating panel opens as an overlay on top of the fallback page.

- [ ] **Step 8: Run existing specs covering this area**

Run: `bundle exec rspec spec/requests/constructors/projects/stages_spec.rb spec/components/constructors/projects/planning/`
Fix any spec that asserted on the old `project_modal`/`stage_detail` frame ids or on the removed `<h1>` title inside `StageDetailComponent` (update those assertions to check the `Qb::DrawerComponent` header instead, at the call site's request-spec level).

- [ ] **Step 9: Commit**

```bash
git add app/views/constructors/projects/stages/show.html.erb app/components/constructors/projects/planning/stage_detail_component.html.erb app/components/constructors/projects/planning/gantt_component.html.erb app/components/constructors/projects/planning/stage_card_component.html.erb app/views/constructors/projects/show.html.erb
git commit -m "feat(drawer): unifica detalle y edición de etapa en un solo panel"
```

---

## Task 8: Etapas — adjuntos (fotos y documentos)

**Files:**
- Modify: `app/views/constructors/projects/stages/images/new.html.erb`
- Modify: `app/views/constructors/projects/stages/documents/new.html.erb`

**Interfaces:**
- Consumes: `Qb::DrawerComponent` (Task 4). No controller change — `Constructors::Projects::Stages::ImagesController#create`/`DocumentsController#create` already do a plain `redirect_to constructors_project_stage_path(@project, @stage)` on success/failure with no format branching; once the form is frame-scoped to `"drawer"` (instead of forced to `"_top"`), Turbo follows that redirect **as a frame-scoped request**, landing on `stages#show`, which (Task 7) renders the refreshed `StageDetailComponent` — now showing the new attachments — straight back into the drawer. Zero controller code changes needed for this task.

- [ ] **Step 1: Convert `stages/images/new.html.erb`**

Replace ONLY the `<% if turbo_frame_request? %>...<% else %>` portion (do NOT touch anything from `<% else %>` onward — that full-page fallback is preserved verbatim, per spec §1):

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Imágenes", title: "Agregar imágenes", subtitle: @stage.name, size: :md)) do %>
      <%= form_with scope: :image, url: constructors_project_stage_images_path(@project, @stage), multipart: true, class: "space-y-5" do |form| %>
        <div class="qb-field">
          <%= form.label :files, "Seleccionar imágenes", class: "qb-label" %>
          <%= form.file_field :files, multiple: true, accept: "image/*",
                              style: "font-size:12px;color:var(--color-ink-2);width:100%;" %>
          <p style="margin-top:4px;font-size:11px;color:var(--color-ink-3);">Formatos recomendados: JPG o PNG (hasta 25 MB cada imagen).</p>
        </div>

        <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
          <%= render Qb::BtnComponent.new('Subir imágenes', variant: :primary, type: 'submit') %>
          <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
        </div>
      <% end %>
    <% end %>
  <% end %>
<% else %>
```

Everything from `<% else %>` to the matching `<% end %>` at the end of the file is the file's EXISTING full-page fallback (currently: `<% project = @project.decorate %>`, `section_tabs`, a header strip titled "Nueva foto", and a centered form at `max-width:560px` with a `href`-based Cancelar button pointing back to the stage) — leave it completely untouched. Only the `<% if turbo_frame_request? %>` branch (and the old `qb--modal`/`turbo_frame_tag "project_modal"` markup it replaces) changes.

- [ ] **Step 2: Convert `stages/documents/new.html.erb`**

Same transformation, mirroring Step 1's structure exactly but for documents — replace ONLY the `<% if turbo_frame_request? %>...<% else %>` portion, leave everything from `<% else %>` onward untouched:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Documentos", title: "Agregar documentos", subtitle: @stage.name, size: :md)) do %>
      <%= form_with scope: :document, url: constructors_project_stage_documents_path(@project, @stage), multipart: true, class: "space-y-5" do |form| %>
        <div class="qb-field">
          <%= form.label :files, "Seleccionar archivos", class: "qb-label" %>
          <%= form.file_field :files, multiple: true, accept: ".pdf,application/pdf",
                              style: "font-size:12px;color:var(--color-ink-2);width:100%;" %>
          <p style="margin-top:4px;font-size:11px;color:var(--color-ink-3);">Formatos admitidos: PDF (hasta 25 MB cada uno).</p>
        </div>

        <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
          <%= render Qb::BtnComponent.new('Subir documentos', variant: :primary, type: 'submit') %>
          <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
        </div>
      <% end %>
    <% end %>
  <% end %>
<% else %>
```

Everything from `<% else %>` onward (existing header strip titled "Nuevo documento", form at `max-width:560px`, `href`-based Cancelar) stays exactly as it is today.

- [ ] **Step 3: Manual smoke check**

From an open stage detail drawer, go to the Fotos tab → "Agregar imágenes" → drawer swaps to the upload form → select a file → submit → drawer returns to the (refreshed) stage detail showing the new photo. Same for Docs/documents.

- [ ] **Step 4: Commit**

```bash
git add app/views/constructors/projects/stages/images/new.html.erb app/views/constructors/projects/stages/documents/new.html.erb
git commit -m "feat(drawer): migra carga de fotos y documentos de etapa al drawer"
```

---

## Task 9: Materiales — crear/editar lista (drawer)

**Files:**
- Modify: `app/controllers/constructors/projects/material_lists_controller.rb`
- Modify: `app/views/constructors/projects/material_lists/new.html.erb`
- Modify: `app/views/constructors/projects/material_lists/edit.html.erb`
- Modify: `app/components/constructors/projects/materials/new_list_modal_component.rb` → rename to `app/components/constructors/projects/materials/new_list_form_component.rb`
- Modify: `app/components/constructors/projects/materials/new_list_modal_component.html.erb` → rename to `app/components/constructors/projects/materials/new_list_form_component.html.erb`
- Modify: `app/views/constructors/projects/material_lists/index.html.erb`
- Modify: `app/views/constructors/projects/planning/stage_detail_component.html.erb` (already renamed in Task 7 — no further change here)

**Interfaces:**
- Produces: `Constructors::Projects::Materials::NewListFormComponent` (renamed from `NewListModalComponent`, same constructor signature `new(project:, stage: nil)`).
- Consumes: the `_detail_drawer` partial from Task 6, Step 0 (`app/views/constructors/projects/stages/_detail_drawer.html.erb`) for the stage-scoped branch.

- [ ] **Step 1: Simplify `material_lists_controller#create` — rename frame, drop the stage/no-stage `_top` split**

Replace (currently lines 65-93):

```ruby
    if @material_list.save
      if @material_list.project_stage_id.present?
        respond_to do |format|
          format.turbo_stream do
            @stage = @material_list.project_stage
            render turbo_stream: [
              turbo_stream.update("project_modal", ""),
              turbo_stream.update("stage_detail",
                Constructors::Projects::Planning::StageDetailComponent.new(
                  project: @project,
                  stage: @stage,
                  sub_stages: @stage.sub_stages.order(:position, :name)
                ))
            ]
          end
          format.html do
            redirect_to constructors_project_stage_path(@project, @material_list.project_stage),
                        notice: "Lista creada."
          end
        end
      else
        redirect_to constructors_project_material_list_path(@project, @material_list),
                    notice: "Lista de materiales creada correctamente."
      end
    else
```

with:

```ruby
    if @material_list.save
      if @material_list.project_stage_id.present?
        respond_to do |format|
          format.turbo_stream do
            @stage = @material_list.project_stage
            render turbo_stream: turbo_stream.update("drawer",
              partial: "constructors/projects/stages/detail_drawer",
              locals: {
                project: @project,
                stage: @stage.decorate,
                sub_stages: @stage.sub_stages.order(:position, :name)
              })
          end
          format.html do
            redirect_to constructors_project_stage_path(@project, @material_list.project_stage),
                        notice: "Lista creada."
          end
        end
      else
        # Sin etapa: el POST llega frame-scoped al frame "drawer" (ya no se
        # fuerza _top en el form); Turbo sigue este redirect como una request
        # de frame y cae en material_lists#show, que ya renderiza su propio
        # detalle dentro de "drawer" — el panel pasa de "form de alta" a
        # "detalle de la lista recién creada" sin salir de la página.
        redirect_to constructors_project_material_list_path(@project, @material_list),
                    notice: "Lista de materiales creada correctamente."
      end
    else
```

- [ ] **Step 2: Convert `material_lists/new.html.erb`**

Replace the frame-request branch (currently lines 7-13):

```erb
<% if turbo_frame_request? %>
  <%= turbo_frame_tag "project_modal" do %>
    <div data-controller="qb--modal" data-qb--modal-open-on-connect-value="true">
      <%= render Constructors::Projects::Materials::NewListModalComponent.new(
            project: @project, stage: @material_list.project_stage) %>
    </div>
  <% end %>
<% else %>
```

with:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Materiales", title: "Nueva lista de materiales", size: :md)) do %>
      <%= render Constructors::Projects::Materials::NewListFormComponent.new(
            project: @project, stage: @material_list.project_stage) %>
    <% end %>
  <% end %>
<% else %>
```

- [ ] **Step 3: Convert `material_lists/edit.html.erb`**

Replace the frame-request branch (currently lines 4-32):

```erb
<% if turbo_frame_request? %>
  <%= turbo_frame_tag "project_modal" do %>
    <div data-controller="qb--modal" data-qb--modal-open-on-connect-value="true">
    <div data-qb--modal-target="dialog" role="dialog" aria-modal="true"
         class="hidden"
         data-action="click->qb--modal#backdrop keydown@window->qb--modal#keydown"
         style="display:flex;position:fixed;inset:0;z-index:60;background:rgba(0,0,0,0.45);align-items:center;justify-content:center;">
      <div data-qb--modal-target="panel"
           style="position:relative;width:720px;max-width:calc(100vw - 32px);max-height:86vh;background:var(--color-bg);border:1px solid var(--color-line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column;box-shadow:0 20px 50px -10px rgba(0,0,0,0.4);">

        <div style="padding:14px 18px;border-bottom:1px solid var(--color-line);display:flex;justify-content:space-between;align-items:center;">
          <div style="min-width:0;flex:1;">
            <div style="font-size:10px;font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.7px;color:var(--color-accent);margin-bottom:4px;">Materiales</div>
            <h3 style="margin:0;font-size:15px;font-weight:600;color:var(--color-ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"><%= title %></h3>
            <div style="font-size:12px;color:var(--color-ink-3);margin-top:2px;"><%= subtitle %></div>
          </div>
          <button type="button" data-action="click->qb--modal#close" aria-label="Cerrar"
                  style="background:transparent;border:none;color:var(--color-ink-3);cursor:pointer;flex-shrink:0;">
            <%= render Qb::IconComponent.new(name: :x, size: 16) %>
          </button>
        </div>

        <div style="flex:1;overflow:auto;padding:18px;">
          <%= render "form" %>
        </div>
      </div>
    </div>
    </div>
  <% end %>
<% else %>
```

with:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Materiales", title: title, subtitle: subtitle, size: :lg)) do %>
      <%= render "form" %>
    <% end %>
  <% end %>
<% else %>
```

(The full-page `else` branch, currently lines 33-60, is unchanged.)

- [ ] **Step 4: Rename `NewListModalComponent` → `NewListFormComponent` and strip its modal chrome**

```bash
git mv app/components/constructors/projects/materials/new_list_modal_component.rb app/components/constructors/projects/materials/new_list_form_component.rb
git mv app/components/constructors/projects/materials/new_list_modal_component.html.erb app/components/constructors/projects/materials/new_list_form_component.html.erb
```

In `new_list_form_component.rb`, rename the class:

```ruby
# frozen_string_literal: true

# Form for creating a new MaterialList, rendered inside Qb::DrawerComponent.
# 3 source-type buttons (Manual / PDF / Excel) plus name, stage, notes.
# Submits via Turbo to the existing material_lists#create.
class Constructors::Projects::Materials::NewListFormComponent < ViewComponent::Base
  SOURCES = [
    { key: :manual,        label: "Manual",         icon: :edit, hint: "Cargar ítems uno por uno" },
    { key: :pdf_upload,    label: "Importar PDF",   icon: :doc,  hint: "Detectar con IA" },
    { key: :excel_upload,  label: "Importar Excel", icon: :grid, hint: "Mapear columnas" }
  ].freeze

  # stage: optional ProjectStage to pre-select (e.g. when opened from a stage's
  # detail "Nueva lista" CTA).
  def initialize(project:, stage: nil)
    @project = project
    @stage = stage
  end

  attr_reader :project, :stage

  def stage_options
    project.project_stages.where(parent_id: nil).order(:position).pluck(:name, :id)
  end

  def selected_stage_id
    stage&.id
  end
end
```

In `new_list_form_component.html.erb`, replace the full contents (strip the outer `data-qb--modal-target="dialog"`/`"panel"` chrome that Qb::DrawerComponent now provides — keep only the form and its footer):

```erb
<%# scope: :material_list → fields post as material_list[...] which is what
    the controller's params.require(:material_list) expects. Sin scope, el
    POST fallaba con ParameterMissing. El form ya no fuerza turbo_frame:
    siempre queda scoped al frame ambiente ("drawer"); material_lists#create
    resuelve el destino (stage_detail refrescado, o el detalle de la lista
    recién creada) sin necesitar un _top. %>
<%= form_with url: helpers.constructors_project_material_lists_path(project), method: :post,
              scope: :material_list,
              html: { style: 'display:flex;flex-direction:column;' } do |f| %>
  <div style="display:flex;flex-direction:column;gap:14px;">
    <label style="display:flex;flex-direction:column;gap:5px;">
      <span style="font-size:11px;font-weight:500;color:var(--color-ink-2);">Nombre <span style="color:var(--color-accent);">*</span></span>
      <%= f.text_field :name, required: true, placeholder: 'Ej: Hierros para estructura · Losas 1°–3°', class: "qb-input" %>
    </label>

    <% if stage %>
      <%# Abierto desde una etapa: se asocia automáticamente, sin selector. %>
      <%= f.hidden_field :project_stage_id, value: stage.id %>
      <div style="display:flex;align-items:center;gap:6px;font-size:11px;color:var(--color-ink-3);">
        <%= render Qb::IconComponent.new(name: :stages, size: 12) %>
        Se asociará a la etapa <span style="color:var(--color-ink);font-weight:500;"><%= stage.name %></span>
      </div>
    <% else %>
      <label style="display:flex;flex-direction:column;gap:5px;">
        <span style="font-size:11px;font-weight:500;color:var(--color-ink-2);">Etapa asociada (opcional)</span>
        <%= f.select :project_stage_id, [['— Sin etapa asociada —', '']] + stage_options, {}, class: "qb-select" %>
      </label>
    <% end %>

    <div>
      <div style="font-size:11px;font-weight:500;color:var(--color-ink-2);margin-bottom:5px;">Origen de datos</div>
      <%= f.hidden_field :source_type, value: 'manual', data: { qb_source_picker_target: 'value' } %>
      <div data-controller="qb--source-picker" style="display:grid;grid-template-columns:repeat(3, 1fr);gap:6px;">
        <% SOURCES.each do |s| %>
          <button type="button"
                  data-action="click->qb--source-picker#pick"
                  data-qb--source-picker-key-param="<%= s[:key] %>"
                  data-qb-source-key="<%= s[:key] %>"
                  data-qb-source-picker-button
                  style="padding:10px;background:<%= s[:key] == :manual ? 'color-mix(in oklab, var(--color-accent) 10%, transparent)' : 'var(--color-bg-raised)' %>;border:1px solid <%= s[:key] == :manual ? 'var(--color-accent)' : 'var(--color-line)' %>;border-radius:6px;cursor:pointer;text-align:left;display:flex;flex-direction:column;gap:4px;color:<%= s[:key] == :manual ? 'var(--color-accent)' : 'var(--color-ink)' %>;">
            <%= render Qb::IconComponent.new(name: s[:icon], size: 14) %>
            <div style="font-size:12px;font-weight:600;"><%= s[:label] %></div>
            <div style="font-size:10.5px;color:var(--color-ink-3);"><%= s[:hint] %></div>
          </button>
        <% end %>
      </div>
    </div>

    <label style="display:flex;flex-direction:column;gap:5px;">
      <span style="font-size:11px;font-weight:500;color:var(--color-ink-2);">Notas (opcional)</span>
      <%= f.text_area :notes, rows: 3, placeholder: 'Contexto, proveedor sugerido, revisiones pendientes…', class: "qb-textarea" %>
    </label>
  </div>

  <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
    <%= render Qb::BtnComponent.new('Crear lista', variant: :primary, icon: :check, type: 'submit') %>
    <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
  </div>
<% end %>
```

- [ ] **Step 5: Rename remaining `NewListModalComponent` references**

Search: `grep -rn "NewListModalComponent" app/` — the only other caller besides `material_lists/new.html.erb` (already updated in Step 2) should be none; if any turn up (e.g. in a spec), rename them to `NewListFormComponent` too.

- [ ] **Step 6: Rename the trigger in `material_lists/index.html.erb`**

At both lines 45 and 47, replace `data: { turbo_frame: 'project_modal' }` with `data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' }`, and delete the trailing bare `turbo_frame_tag "project_modal"` at line 116.

- [ ] **Step 7: Manual smoke check**

From the Materiales index: "Nueva lista" → drawer opens with the create form → submit without a stage → drawer swaps to the new list's own detail view (Task 10) → close → index unaffected until reloaded (documented, acceptable per plan rationale). From a stage detail's Materiales tab: "Nueva lista" → drawer swaps to the create form pre-filled with that stage → submit → drawer returns to the (refreshed) stage detail showing the new list.

- [ ] **Step 8: Commit**

```bash
git add app/controllers/constructors/projects/material_lists_controller.rb app/views/constructors/projects/material_lists/new.html.erb app/views/constructors/projects/material_lists/edit.html.erb app/components/constructors/projects/materials/new_list_form_component.rb app/components/constructors/projects/materials/new_list_form_component.html.erb app/views/constructors/projects/material_lists/index.html.erb
git commit -m "feat(drawer): migra alta/edición de listas de materiales al drawer"
```

---

## Task 10: Materiales — detalle de lista (re-skin)

**Files:**
- Modify: `app/views/constructors/projects/material_lists/show.html.erb`
- Modify: `app/components/constructors/projects/materials/list_detail_component.html.erb`
- Modify: `app/components/constructors/projects/materials/list_card_component.html.erb`

**Interfaces:**
- Consumes: `Qb::DrawerComponent`'s `custom_header` slot (this view has its own rich pills/actions header, not a plain eyebrow/title).

- [ ] **Step 1: Convert `material_lists/show.html.erb`**

Replace the frame-request branch:

```erb
<% if turbo_frame_request? %>
  <%= turbo_frame_tag "project_modal" do %>
    <div data-controller="qb--drawer">
      <%= render Constructors::Projects::Materials::ListDetailComponent.new(...) %>
    </div>
  <% end %>
<% else %>
```

with:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render Constructors::Projects::Materials::ListDetailComponent.new(...) %>
  <% end %>
<% else %>
```

(Keep whatever the actual `ListDetailComponent.new(...)` call arguments are today — this task only changes the surrounding frame/controller wiring, not the component's inputs. Read the current file first to copy the exact constructor call verbatim.)

- [ ] **Step 2: Re-skin `list_detail_component.html.erb` to render inside `Qb::DrawerComponent`**

Replace the outer dialog/panel chrome (currently lines 1-6):

```erb
<div data-qb--drawer-target="dialog" role="dialog" aria-modal="true"
     class="hidden"
     data-action="click->qb--drawer#backdrop keydown@window->qb--drawer#keydown"
     style="display:flex;position:fixed;inset:0;z-index:50;background:rgba(0,0,0,0.40);justify-content:flex-end;">
  <div data-qb--drawer-target="panel"
       style="position:relative;width:880px;max-width:100vw;background:var(--color-bg);border-left:1px solid var(--color-line);display:flex;flex-direction:column;overflow:hidden;height:100vh;">
```

with:

```erb
<%= render(Qb::DrawerComponent.new(size: :xl)) do |d| %>
  <% d.with_custom_header do %>
```

And replace the closing tags at the very end of the file (currently the last two `</div>` lines closing `panel` and `dialog`) so the file ends with:

```erb
  <% end %>
<% end %>
```

Inside this restructure: the existing header block (lines 8-61: close button, pills, title, Exportar/Editar/Pagar/Aprobar action buttons) becomes the content of `d.with_custom_header do ... end`, wrapped in `<div class="qb-drawer-header">...</div>` instead of its current raw inline-styled div — reuse the exact same inner content (pills, buttons, conditionals) but swap the outer wrapper div's `style="padding:14px 20px;border-bottom:...` for `class="qb-drawer-header"`, and the close button's `data-action="click->qb--drawer#close"` (already correct, no change needed there). Everything from the metadata strip onward (today's lines 63+: metadata grid, notes, items table, footer) becomes the component's default `content` block (i.e., stays exactly where it is, just now inside `<%= render(Qb::DrawerComponent.new(size: :xl)) do |d| %> ... <% end %>` rather than the old raw `dialog`/`panel` divs) — no `.qb-drawer-body`/`.qb-drawer-footer` wrapper needed around it since this content mixes scrollable + sticky-footer sections that the component's plain `content` slot doesn't split automatically; leave its existing `style="flex:1;overflow:auto;"` items-table wrapper and `style="padding:12px 20px;border-top:..."` footer wrapper exactly as they are today (they already implement the same visual pattern by hand).

Also rename, within this same file: `edit_constructors_project_material_list_path(project, list), data: { turbo_frame: 'project_modal' }` → `data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' }`.

- [ ] **Step 3: Rename the trigger in `list_card_component.html.erb`**

Replace `data: { turbo_frame: 'project_modal' }` with `data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' }`.

- [ ] **Step 4: Manual smoke check**

From the Materiales index, click a list card → drawer slides in (880px wide) with the full detail (pills, metadata, items table, footer totals). Click "Editar" → panel swaps to the edit form (Task 9). Click "Exportar" → CSV downloads without disturbing the panel (already `data: { turbo: false }`, unaffected by this migration).

- [ ] **Step 5: Commit**

```bash
git add app/views/constructors/projects/material_lists/show.html.erb app/components/constructors/projects/materials/list_detail_component.html.erb app/components/constructors/projects/materials/list_card_component.html.erb
git commit -m "feat(drawer): reskin del detalle de lista de materiales"
```

---

## Task 11: Planos — subir plano

**Files:**
- Modify: `app/controllers/constructors/projects/blueprints_controller.rb`
- Modify: `app/views/constructors/projects/blueprints/new.html.erb`
- Modify: `app/components/constructors/projects/blueprints/upload_modal_component.rb` → rename to `upload_form_component.rb`
- Modify: `app/components/constructors/projects/blueprints/upload_modal_component.html.erb` → rename to `upload_form_component.html.erb`
- Modify: `app/views/constructors/projects/blueprints/index.html.erb`

**Interfaces:**
- Produces: `blueprints_controller#create` gains a `format.turbo_stream` branch (new — today it's a plain `redirect_to`/`render :new`), guarded for mobile per Global Constraints.

- [ ] **Step 1: Add the turbo_stream branch to `blueprints_controller#create`**

`blueprints/index.html.erb` is a single unified view (list + real canvas viewer + AI panel, all rendered as one `Constructors::Projects::Blueprints::WorkspaceComponent`, keyed by `?selected=:id`) — there is no simple addressable "grid" sub-container to prepend a new card into without reaching into that component's internals. `turbo_stream.refresh` is the right tool here, same reasoning as project/person edit: close the drawer and let Turbo's native page-morph refresh show the newly uploaded blueprint (pre-selected via `selected:` once the page re-renders), instead of hand-patching a complex nested component.

Replace (currently lines 32-43):

```ruby
  def create
    authorize @project, :manage_content?
    @blueprint = @project.blueprints.build(blueprint_params)

    if @blueprint.save
      redirect_to constructors_project_blueprints_path(@project, selected: @blueprint.id),
                  notice: "Plano subido correctamente."
    else
      flash.now[:alert] = "Revisá los datos y volvé a intentarlo."
      render :new, status: :unprocessable_entity
    end
  end
```

with:

```ruby
  def create
    authorize @project, :manage_content?
    @blueprint = @project.blueprints.build(blueprint_params)

    if @blueprint.save
      respond_to do |format|
        format.turbo_stream do
          if request.variant.include?(:mobile)
            redirect_to constructors_project_blueprints_path(@project, selected: @blueprint.id),
                        notice: "Plano subido correctamente."
          else
            render turbo_stream: turbo_stream.refresh
          end
        end
        format.html do
          redirect_to constructors_project_blueprints_path(@project, selected: @blueprint.id),
                      notice: "Plano subido correctamente."
        end
      end
    else
      flash.now[:alert] = "Revisá los datos y volvé a intentarlo."
      render :new, status: :unprocessable_entity
    end
  end
```

Note: `turbo_stream.refresh` re-visits the CURRENT URL (the one the drawer was opened from), not `constructors_project_blueprints_path(@project, selected: @blueprint.id)` — so the freshly uploaded blueprint won't be auto-selected in the viewer after a refresh-triggered reload the way the old full-page redirect used to select it. This is an accepted, minor UX regression on this ONE call site (documented here rather than silently dropped) — the new blueprint is still visible in the list immediately after refresh, just not auto-opened in the viewer. If this proves annoying in practice, a follow-up could special-case `redirect_to ...selected: @blueprint.id` for the non-mobile turbo_stream branch too (a real `redirect_to` is also followed correctly even under `format.turbo_stream`), trading the "refresh other stale KPIs on this page" benefit for "auto-select the new blueprint" — but that reopens the original staleness question this task avoided, so don't make that swap without first confirming nothing else on this page needs the refresh.

- [ ] **Step 2: Convert `blueprints/new.html.erb`**

Replace the frame-request branch (currently lines 7-13):

```erb
<% if turbo_frame_request? %>
  <%= turbo_frame_tag 'project_modal' do %>
    <div data-controller="qb--modal" data-qb--modal-open-on-connect-value="true">
      <%= render Constructors::Projects::Blueprints::UploadModalComponent.new(
            project: @project, blueprint: @blueprint) %>
    </div>
  <% end %>
<% else %>
```

with:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Planos", title: "Subir plano", size: :md)) do %>
      <%= render Constructors::Projects::Blueprints::UploadFormComponent.new(
            project: @project, blueprint: @blueprint) %>
    <% end %>
  <% end %>
<% else %>
```

- [ ] **Step 3: Rename `UploadModalComponent` → `UploadFormComponent`, strip modal chrome, drop `_top`**

```bash
git mv app/components/constructors/projects/blueprints/upload_modal_component.rb app/components/constructors/projects/blueprints/upload_form_component.rb
git mv app/components/constructors/projects/blueprints/upload_modal_component.html.erb app/components/constructors/projects/blueprints/upload_form_component.html.erb
```

`upload_form_component.rb`:

```ruby
# frozen_string_literal: true

# Form to upload a blueprint, rendered inside Qb::DrawerComponent. On success
# blueprints_controller#create closes the drawer and prepends the new card to
# the index grid — no page navigation needed.
class Constructors::Projects::Blueprints::UploadFormComponent < ViewComponent::Base
  def initialize(project:, blueprint:)
    @project = project
    @blueprint = blueprint
  end

  attr_reader :project, :blueprint
end
```

`upload_form_component.html.erb` (strip the outer dialog/panel/header, keep the form with its fields, drop `data: { turbo_frame: '_top' }`, change the Cancel button and footer to the drawer pattern):

```erb
<%= form_with model: blueprint,
              url: helpers.constructors_project_blueprints_path(project),
              html: { multipart: true, style: 'display:flex;flex-direction:column;' } do |f| %>
  <% if blueprint.errors.any? %>
    <div class="qb-form-error">
      <p style="font-weight:600;margin:0 0 4px;">No se pudo subir el plano:</p>
      <ul style="margin:0;padding-left:16px;">
        <% blueprint.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="qb-field">
    <%= f.label :name, 'Nombre del plano', class: 'qb-label' %>
    <%= f.text_field :name, required: true, placeholder: 'Ej: Planta baja · Arquitectura', class: 'qb-input' %>
  </div>

  <div class="qb-field">
    <%= f.label :description, 'Descripción (opcional)', class: 'qb-label' %>
    <%= f.text_area :description, rows: 2, placeholder: 'Ej: distribución de ambientes, revisión 3', class: 'qb-textarea' %>
  </div>

  <div class="qb-field">
    <%= f.label :file, 'Archivo del plano', class: 'qb-label' %>
    <%= f.file_field :file,
          required: true,
          accept: 'image/jpeg,image/png,image/jpg',
          direct_upload: true,
          style: 'display:block;font-size:12px;color:var(--color-ink-2);width:100%;padding:10px;border:1px dashed var(--color-line-2);border-radius:var(--radius);background:var(--color-bg-sunken);' %>
    <p style="font-size:11px;color:var(--color-ink-4);margin:4px 0 0;">JPG o PNG, hasta 10MB. Después definís la escala y medís sobre el plano.</p>
  </div>

  <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
    <%= render Qb::BtnComponent.new('Subir plano', variant: :primary, icon: :upload, type: 'submit') %>
    <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
  </div>
<% end %>
```

- [ ] **Step 4: Rename the trigger and delete the placeholder in `blueprints/index.html.erb`**

At line 28, replace `data: { turbo_frame: 'project_modal' })` with `data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' })`. Delete the trailing bare `turbo_frame_tag 'project_modal'` at line 49.

- [ ] **Step 5: Manual smoke check**

From Planos index, "Subir plano" → drawer opens → pick a file, submit → drawer closes, new card appears at the top of the grid without a page reload.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/constructors/projects/blueprints_controller.rb app/views/constructors/projects/blueprints/new.html.erb app/components/constructors/projects/blueprints/upload_form_component.rb app/components/constructors/projects/blueprints/upload_form_component.html.erb app/views/constructors/projects/blueprints/index.html.erb
git commit -m "feat(drawer): migra carga de planos al drawer"
```

---

## Task 12: Personas — alta/edición por obra

**Files:**
- Modify: `app/controllers/constructors/projects/people_controller.rb`
- Modify: `app/views/constructors/projects/people/new.html.erb`
- Modify: `app/views/constructors/projects/people/edit.html.erb`
- Modify: `app/components/constructors/projects/people/person_form_component.html.erb`
- Modify: `app/views/constructors/projects/people/index.html.erb`

**Interfaces:**
- Produces: `Projects::PeopleController#update` gains a `format.turbo_stream` success branch using `turbo_stream.refresh` (new), guarded for mobile.

- [ ] **Step 1: Rename the frame in `create`'s existing turbo_stream branch**

Replace (currently lines 52-59):

```ruby
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("project_modal", ""),
            turbo_stream.remove("people_empty_row"),
            turbo_stream.append("people_rows",
              partial: "constructors/projects/people/person_row",
              locals: { person: @person, project: @project })
          ]
        end
```

with:

```ruby
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("drawer", ""),
            turbo_stream.remove("people_empty_row"),
            turbo_stream.append("people_rows",
              partial: "constructors/projects/people/person_row",
              locals: { person: @person, project: @project })
          ]
        end
```

- [ ] **Step 2: Add a `turbo_stream.refresh` branch to `update`**

Replace:

```ruby
  def update
    authorize @person
    if @person.update(person_params)
      redirect_to constructors_project_person_path(@project, @person), notice: "Datos actualizados."
    else
      render :edit, status: :unprocessable_entity
    end
  end
```

with:

```ruby
  def update
    authorize @person
    if @person.update(person_params)
      respond_to do |format|
        format.turbo_stream do
          if request.variant.include?(:mobile)
            redirect_to constructors_project_person_path(@project, @person), notice: "Datos actualizados."
          else
            # La ficha editada puede estar visible en más de un lugar de la
            # página actual (fila del listado, resumen del equipo): un simple
            # patch del frame "drawer" la cerraría pero dejaría esos otros
            # lugares con el dato viejo. El refresh nativo de Turbo 8 cierra
            # el drawer (la próxima carga no trae contenido para él) Y
            # refresca toda la página actual en un solo paso.
            render turbo_stream: turbo_stream.refresh
          end
        end
        format.html { redirect_to constructors_project_person_path(@project, @person), notice: "Datos actualizados." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end
```

- [ ] **Step 3: Convert `people/new.html.erb`**

Replace the frame-request branch (currently lines 5-35):

```erb
<% if turbo_frame_request? %>
  <%= turbo_frame_tag "project_modal" do %>
    <div data-controller="qb--modal" data-qb--modal-open-on-connect-value="true">
    <div data-qb--modal-target="dialog" role="dialog" aria-modal="true"
         class="hidden"
         data-action="click->qb--modal#backdrop keydown@window->qb--modal#keydown"
         style="display:flex;position:fixed;inset:0;z-index:60;background:rgba(0,0,0,0.45);align-items:center;justify-content:center;">
      <div data-qb--modal-target="panel"
           style="position:relative;width:640px;max-height:86vh;background:var(--color-bg);border:1px solid var(--color-line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column;box-shadow:0 20px 50px -10px rgba(0,0,0,0.4);">

        <div style="padding:14px 18px;border-bottom:1px solid var(--color-line);display:flex;justify-content:space-between;align-items:center;">
          <div>
            <div style="font-size:10px;font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.7px;color:var(--color-accent);margin-bottom:4px;">Equipo</div>
            <h3 style="margin:0;font-size:15px;font-weight:600;color:var(--color-ink);">Nueva persona</h3>
            <div style="font-size:12px;color:var(--color-ink-3);margin-top:2px;">Cargá los datos básicos del trabajador u oficio.</div>
          </div>
          <button type="button" data-action="click->qb--modal#close" aria-label="Cerrar"
                  style="background:transparent;border:none;color:var(--color-ink-3);cursor:pointer;">
            <%= render Qb::IconComponent.new(name: :x, size: 16) %>
          </button>
        </div>

        <div style="flex:1;overflow:auto;padding:18px;">
          <div class="qb-card" style="padding:16px;">
            <%= render Constructors::Projects::People::PersonFormComponent.new(project: @project, person: @person) %>
          </div>
        </div>
      </div>
    </div>
    </div>
  <% end %>
<% else %>
```

with:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Equipo", title: "Nueva persona", subtitle: "Cargá los datos básicos del trabajador u oficio", size: :lg)) do %>
      <%= render Constructors::Projects::People::PersonFormComponent.new(project: @project, person: @person) %>
    <% end %>
  <% end %>
<% else %>
```

- [ ] **Step 4: Add a drawer branch to `people/edit.html.erb`** (today it's full-page only)

Replace the full contents of `app/views/constructors/projects/people/edit.html.erb`:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Equipo", title: "Editar persona", subtitle: @person.full_name, size: :lg)) do %>
      <%= render Constructors::Projects::People::PersonFormComponent.new(project: @project, person: @person) %>
    <% end %>
  <% end %>
<% else %>
  <%= render 'constructors/projects/section_tabs', project: @project, current: :team %>

  <div style="padding:14px 20px;border-bottom:1px solid var(--color-line);display:flex;align-items:flex-end;gap:16px;">
    <div style="flex:1;">
      <div style="font-size:11px;font-family:var(--font-mono);color:var(--color-ink-3);text-transform:uppercase;letter-spacing:0.8px;"><%= @project.decorate.code %> · Equipo</div>
      <h2 style="margin:3px 0 0;font-size:18px;font-weight:600;letter-spacing:-0.3px;">Editar persona</h2>
      <div style="font-size:12px;color:var(--color-ink-3);margin-top:2px;">
        Actualizá la información de <strong><%= @person.full_name %></strong>
        · <%= link_to '← Volver a la ficha', constructors_project_person_path(@project, @person), style: 'color:var(--color-accent);text-decoration:none;font-size:12px;' %>
      </div>
    </div>
  </div>

  <div style="padding:28px 20px;">
    <div style="max-width:560px;margin:0 auto;">
      <%= render Constructors::Projects::People::PersonFormComponent.new(project: @project, person: @person) %>
    </div>
  </div>
<% end %>
```

- [ ] **Step 5: Update `PersonFormComponent`'s Cancel button**

Replace (currently line 79):

```erb
    <%# _top: dentro del modal (project_modal) navega al índice en vez de cargarlo dentro del frame. %>
    <%= render Qb::BtnComponent.new("Cancelar", variant: :secondary, size: :md, href: cancel_href, data: { turbo_frame: '_top' }) %>
```

with:

```erb
    <%= render Qb::BtnComponent.new("Cancelar", variant: :secondary, size: :md, data: { action: 'click->qb--drawer#close' }) %>
```

(`cancel_href` becomes unused inside this component template — check `person_form_component.rb` for whether `cancel_href` is still referenced elsewhere in the same file before removing its definition; if it's now fully unused, leave the method as-is rather than risk breaking something outside this task's scope — it's a private helper, harmless if temporarily unused.)

- [ ] **Step 6: Rename the trigger in `people/index.html.erb`**

At line 65, replace `data: { turbo_frame: 'project_modal' })` with `data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' })`. Delete the trailing bare `turbo_frame_tag "project_modal"` at line 115.

- [ ] **Step 7: Manual smoke check**

From a project's Equipo tab: "Nueva persona" → drawer opens → save → drawer closes, row appears in the list. Click a person's kebab/edit → drawer opens with their data → change the name → save → drawer closes and the page refreshes showing the new name in the row.

- [ ] **Step 8: Commit**

```bash
git add app/controllers/constructors/projects/people_controller.rb app/views/constructors/projects/people/new.html.erb app/views/constructors/projects/people/edit.html.erb app/components/constructors/projects/people/person_form_component.html.erb app/views/constructors/projects/people/index.html.erb
git commit -m "feat(drawer): migra alta/edición de personas por obra al drawer"
```

---

## Task 13: Personas — ficha global (edición)

**Files:**
- Modify: `app/controllers/constructors/people_controller.rb`
- Modify: `app/views/constructors/people/edit.html.erb`

**Interfaces:**
- Produces: `Constructors::PeopleController#update` gains a `format.turbo_stream` success branch using `turbo_stream.refresh`, guarded for mobile. Failure path is unchanged (`render :edit, status: :unprocessable_entity` already re-renders in place — no redirect involved, so it stays frame-friendly with no code change needed there).

- [ ] **Step 1: Add the turbo_stream branch to `update`**

Replace (currently lines 87-103):

```ruby
  def update
    authorize :people, :index_global?
    set_person
    @assignments = siblings_of(@person)

    ActiveRecord::Base.transaction do
      @assignments.each { |a| a.update!(person_params) }
    end
    redirect_to constructors_person_path(@person),
                notice: "Datos actualizados en #{@assignments.size} #{@assignments.size == 1 ? 'asignación' : 'asignaciones'}."
  rescue ActiveRecord::RecordInvalid => e
    @current_qb_section = :team
    @person.assign_attributes(person_params)
    @person.validate
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :edit, status: :unprocessable_entity
  end
```

with:

```ruby
  def update
    authorize :people, :index_global?
    set_person
    @assignments = siblings_of(@person)

    ActiveRecord::Base.transaction do
      @assignments.each { |a| a.update!(person_params) }
    end

    notice = "Datos actualizados en #{@assignments.size} #{@assignments.size == 1 ? 'asignación' : 'asignaciones'}."
    respond_to do |format|
      format.turbo_stream do
        if request.variant.include?(:mobile)
          redirect_to constructors_person_path(@person), notice: notice
        else
          render turbo_stream: turbo_stream.refresh
        end
      end
      format.html { redirect_to constructors_person_path(@person), notice: notice }
    end
  rescue ActiveRecord::RecordInvalid => e
    @current_qb_section = :team
    @person.assign_attributes(person_params)
    @person.validate
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :edit, status: :unprocessable_entity
  end
```

- [ ] **Step 2: Add a drawer branch to `people/edit.html.erb`** (global — today full-page only)

The current file (verified directly, not reconstructed from memory) is:

```erb
<% content_for :qb_crumbs, [{ label: 'Inicio' }, { label: 'Personas' }, { label: @person.full_name }, { label: 'Editar' }].to_json %>
<% content_for :title, "Editar #{@person.full_name} · Quick Build" %>

<div>
  <%# Header strip %>
  <div style="padding:14px 20px;border-bottom:1px solid var(--color-line);display:flex;align-items:flex-end;gap:16px;">
    <div style="flex:1;">
      <div style="font-size:11px;font-family:var(--font-mono);color:var(--color-ink-3);text-transform:uppercase;letter-spacing:0.8px;">Personas · global</div>
      <h1 style="margin:3px 0 0;font-size:20px;font-weight:600;letter-spacing:-0.3px;">Editar datos de <%= @person.full_name %></h1>
      <div style="font-size:12px;color:var(--color-ink-3);margin-top:2px;">
        Los cambios se aplican a sus <%= @assignments.size %> <%= @assignments.size == 1 ? 'asignación' : 'asignaciones' %> en obra.
        <%= link_to '← Volver a la ficha', constructors_person_path(@person), style: 'color:var(--color-accent);text-decoration:none;margin-left:8px;' %>
      </div>
    </div>
  </div>

  <div style="padding:24px 20px;border-bottom:1px solid var(--color-line);">
    <div style="max-width:560px;margin:0 auto;">
      <% if flash.now[:alert].present? %>
        <div class="qb-form-error" style="margin-bottom:14px;"><%= flash.now[:alert] %></div>
      <% end %>

      <%# Sólo la identidad: es lo único que se propaga a todas las asignaciones.
          Rol, vigencia, tarifa y notas son por obra y viven en el form de obra. %>
      <%= form_with model: @person, url: constructors_person_path(@person), method: :patch,
                    scope: :project_person, data: { turbo_frame: "_top" } do |f| %>
        <%= render Qb::FormGroupComponent.new(title: 'Identidad',
              footnote: 'Nombre + teléfono son la clave que agrupa a la persona entre obras.') do %>
          <div class="qb-field">
            <%= f.label :full_name, 'Nombre y apellido', class: "qb-label" %>
            <%= f.text_field :full_name, class: "qb-input", required: true %>
          </div>

          <div class="qb-field">
            <%= f.label :phone, 'Teléfono', class: "qb-label" %>
            <%= f.text_field :phone, class: "qb-input" %>
          </div>

          <div class="qb-field" style="margin-bottom:0;">
            <%= f.label :document_id, 'Documento', class: "qb-label" %>
            <%= f.text_field :document_id, class: "qb-input" %>
          </div>
        <% end %>

        <div style="display:flex;align-items:center;gap:8px;padding-top:14px;border-top:1px solid var(--color-line);">
          <div style="flex:1;"></div>
          <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, size: :md, href: constructors_person_path(@person)) %>
          <%= render Qb::BtnComponent.new('Guardar cambios', variant: :primary, size: :md, type: :submit) %>
        </div>
      <% end %>
    </div>
  </div>

  <%# Contexto: qué asignaciones se van a actualizar %>
  <%= render Qb::SectionHeadComponent.new(title: 'Asignaciones afectadas',
        subtitle: 'Rol, vigencia, tarifa y notas se editan dentro de cada obra.') %>
  <table class="qb-table">
    <thead>
      <tr style="background:var(--color-bg-raised);">
        <th>Obra</th>
        <th>Rol</th>
        <th>Estado</th>
        <th style="text-align:right;"></th>
      </tr>
    </thead>
    <tbody>
      <% @assignments.each do |a| %>
        <% active = a.status.to_s == 'active' %>
        <tr>
          <td>
            <span class="qb-mono" style="font-size:10px;color:var(--color-ink-3);"><%= a.project.decorate.code %></span>
            <span style="display:block;"><%= a.project.name %></span>
          </td>
          <td style="color:var(--color-ink-2);"><%= a.role_title.presence || '—' %></td>
          <td>
            <%= render Qb::PillComponent.new(active ? 'Activa' : 'Inactiva', tone: active ? :ok : :muted, compact: true) %>
          </td>
          <td style="text-align:right;white-space:nowrap;">
            <%= link_to 'Editar en obra', edit_constructors_project_person_path(a.project, a),
                  style: 'color:var(--color-accent);text-decoration:none;font-size:12px;' %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

Wrap it as follows — add the `<% if turbo_frame_request? %>` drawer branch, keep the `content_for` calls unconditional at the top (harmless during a frame request, needed for the full-page case), and move everything from the current single body into the `<% else %>` branch, completely unchanged:

```erb
<% content_for :qb_crumbs, [{ label: 'Inicio' }, { label: 'Personas' }, { label: @person.full_name }, { label: 'Editar' }].to_json %>
<% content_for :title, "Editar #{@person.full_name} · Quick Build" %>

<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(
          eyebrow: "Personas · global",
          title: "Editar datos de #{@person.full_name}",
          subtitle: "Los cambios se aplican a sus #{@assignments.size} #{@assignments.size == 1 ? 'asignación' : 'asignaciones'} en obra.",
          size: :md
        )) do %>
      <% if flash.now[:alert].present? %>
        <div class="qb-form-error" style="margin-bottom:14px;"><%= flash.now[:alert] %></div>
      <% end %>

      <%# Sólo la identidad: es lo único que se propaga a todas las asignaciones.
          Rol, vigencia, tarifa y notas son por obra y viven en el form de obra.
          La tabla de "Asignaciones afectadas" de la página completa no se
          repite acá — mismo criterio que la edición de obra (Task 15): el
          drawer muestra sólo los campos editables, el contexto de sólo
          lectura queda para el fallback de página completa. %>
      <%= form_with model: @person, url: constructors_person_path(@person), method: :patch,
                    scope: :project_person do |f| %>
        <%= render Qb::FormGroupComponent.new(title: 'Identidad',
              footnote: 'Nombre + teléfono son la clave que agrupa a la persona entre obras.') do %>
          <div class="qb-field">
            <%= f.label :full_name, 'Nombre y apellido', class: "qb-label" %>
            <%= f.text_field :full_name, class: "qb-input", required: true %>
          </div>

          <div class="qb-field">
            <%= f.label :phone, 'Teléfono', class: "qb-label" %>
            <%= f.text_field :phone, class: "qb-input" %>
          </div>

          <div class="qb-field" style="margin-bottom:0;">
            <%= f.label :document_id, 'Documento', class: "qb-label" %>
            <%= f.text_field :document_id, class: "qb-input" %>
          </div>
        <% end %>

        <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
          <%= render Qb::BtnComponent.new('Guardar cambios', variant: :primary, size: :md, type: :submit) %>
          <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, size: :md, data: { action: 'click->qb--drawer#close' }) %>
        </div>
      <% end %>
    <% end %>
  <% end %>
<% else %>
  <div>
    <%# Header strip %>
    <div style="padding:14px 20px;border-bottom:1px solid var(--color-line);display:flex;align-items:flex-end;gap:16px;">
      <div style="flex:1;">
        <div style="font-size:11px;font-family:var(--font-mono);color:var(--color-ink-3);text-transform:uppercase;letter-spacing:0.8px;">Personas · global</div>
        <h1 style="margin:3px 0 0;font-size:20px;font-weight:600;letter-spacing:-0.3px;">Editar datos de <%= @person.full_name %></h1>
        <div style="font-size:12px;color:var(--color-ink-3);margin-top:2px;">
          Los cambios se aplican a sus <%= @assignments.size %> <%= @assignments.size == 1 ? 'asignación' : 'asignaciones' %> en obra.
          <%= link_to '← Volver a la ficha', constructors_person_path(@person), style: 'color:var(--color-accent);text-decoration:none;margin-left:8px;' %>
        </div>
      </div>
    </div>

    <div style="padding:24px 20px;border-bottom:1px solid var(--color-line);">
      <div style="max-width:560px;margin:0 auto;">
        <% if flash.now[:alert].present? %>
          <div class="qb-form-error" style="margin-bottom:14px;"><%= flash.now[:alert] %></div>
        <% end %>

        <%# Sólo la identidad: es lo único que se propaga a todas las asignaciones.
            Rol, vigencia, tarifa y notas son por obra y viven en el form de obra. %>
        <%= form_with model: @person, url: constructors_person_path(@person), method: :patch,
                      scope: :project_person, data: { turbo_frame: "_top" } do |f| %>
          <%= render Qb::FormGroupComponent.new(title: 'Identidad',
                footnote: 'Nombre + teléfono son la clave que agrupa a la persona entre obras.') do %>
            <div class="qb-field">
              <%= f.label :full_name, 'Nombre y apellido', class: "qb-label" %>
              <%= f.text_field :full_name, class: "qb-input", required: true %>
            </div>

            <div class="qb-field">
              <%= f.label :phone, 'Teléfono', class: "qb-label" %>
              <%= f.text_field :phone, class: "qb-input" %>
            </div>

            <div class="qb-field" style="margin-bottom:0;">
              <%= f.label :document_id, 'Documento', class: "qb-label" %>
              <%= f.text_field :document_id, class: "qb-input" %>
            </div>
          <% end %>

          <div style="display:flex;align-items:center;gap:8px;padding-top:14px;border-top:1px solid var(--color-line);">
            <div style="flex:1;"></div>
            <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, size: :md, href: constructors_person_path(@person)) %>
            <%= render Qb::BtnComponent.new('Guardar cambios', variant: :primary, size: :md, type: :submit) %>
          </div>
        <% end %>
      </div>
    </div>

    <%# Contexto: qué asignaciones se van a actualizar %>
    <%= render Qb::SectionHeadComponent.new(title: 'Asignaciones afectadas',
          subtitle: 'Rol, vigencia, tarifa y notas se editan dentro de cada obra.') %>
    <table class="qb-table">
      <thead>
        <tr style="background:var(--color-bg-raised);">
          <th>Obra</th>
          <th>Rol</th>
          <th>Estado</th>
          <th style="text-align:right;"></th>
        </tr>
      </thead>
      <tbody>
        <% @assignments.each do |a| %>
          <% active = a.status.to_s == 'active' %>
          <tr>
            <td>
              <span class="qb-mono" style="font-size:10px;color:var(--color-ink-3);"><%= a.project.decorate.code %></span>
              <span style="display:block;"><%= a.project.name %></span>
            </td>
            <td style="color:var(--color-ink-2);"><%= a.role_title.presence || '—' %></td>
            <td>
              <%= render Qb::PillComponent.new(active ? 'Activa' : 'Inactiva', tone: active ? :ok : :muted, compact: true) %>
            </td>
            <td style="text-align:right;white-space:nowrap;">
              <%= link_to 'Editar en obra', edit_constructors_project_person_path(a.project, a),
                    style: 'color:var(--color-accent);text-decoration:none;font-size:12px;' %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
<% end %>
```

This is a straight wrap: the `<% else %>` branch is the file's exact pre-existing body, untouched. The frame-request branch reuses the identical field set (`full_name`/`phone`/`document_id`, same `Qb::FormGroupComponent`), with the "Asignaciones afectadas" table deliberately left out of the drawer (same scope decision as Task 15's project-edit drawer: the panel shows only what's editable, read-only context stays on the full-page fallback) — note this explicitly in the implementation, it's not an oversight.

- [ ] **Step 3: Manual smoke check**

From the global Personas index, open a person's ficha, edit name/phone, save → drawer closes and the page (ficha or index, wherever it was opened from) refreshes showing the new data.

- [ ] **Step 4: Commit**

```bash
git add app/controllers/constructors/people_controller.rb app/views/constructors/people/edit.html.erb
git commit -m "feat(drawer): migra edición de ficha global de persona al drawer"
```

---

## Task 14: Proyecto — crear obra

**Files:**
- Modify: `app/controllers/constructors/projects_controller.rb`
- Modify: `app/views/constructors/projects/new.html.erb`
- Delete: `app/views/constructors/projects/create.turbo_stream.erb`

**Interfaces:**
- Produces: `projects_controller#create` gains an EXPLICIT `respond_to` block using the custom `redirect` stream action (Task 3) — this replaces reliance on the implicit `create.turbo_stream.erb` template, which is dead code today (the action always explicitly calls `redirect_to`/`render`, so Rails never reaches implicit template lookup; the file is deleted as part of this task).

- [ ] **Step 1: Delete the dead turbo_stream template**

```bash
git rm app/views/constructors/projects/create.turbo_stream.erb
```

- [ ] **Step 2: Wire the explicit `respond_to` block in `create`**

Replace (currently lines 82-93):

```ruby
  def create
    @project = current_user.owned_projects.build(project_params)
    authorize @project

    if persist_project_with_documents(@project)
      flash[:new_project] = true
      redirect_to constructors_project_path(@project), notice: "¡Obra creada correctamente!"
    else
      flash.now[:alert] = "Revisa los datos y vuelve a intentarlo."
      render :new, status: :unprocessable_entity
    end
  end
```

with:

```ruby
  def create
    @project = current_user.owned_projects.build(project_params)
    authorize @project

    if persist_project_with_documents(@project)
      flash[:new_project] = true
      flash[:notice] = "¡Obra creada correctamente!"
      respond_to do |format|
        format.turbo_stream do
          if request.variant.include?(:mobile)
            redirect_to constructors_project_path(@project)
          else
            # Única excepción de las 18 migradas: crear una obra abandona por
            # completo el contexto actual (sidebar, obra activa, etc.), así
            # que un patch in-place del frame "drawer" no alcanza — hace
            # falta una navegación real de página. El flash ya quedó seteado
            # en esta respuesta y se muestra en la página de destino.
            render turbo_stream: turbo_stream.action(:redirect, constructors_project_path(@project))
          end
        end
        format.html { redirect_to constructors_project_path(@project) }
      end
    else
      flash.now[:alert] = "Revisa los datos y vuelve a intentarlo."
      render :new, status: :unprocessable_entity
    end
  end
```

- [ ] **Step 3: Add a drawer branch to `projects/new.html.erb`**

`_form.html.erb` (the partial `edit.html.erb` already uses, touched again in Task 15) does **not** have a `budget_pesos` field, `client` field, or the "Documentación de soporte" section's exact layout that `new.html.erb`'s own hand-rolled form has today — reusing it here would silently drop the budget field from project creation and break `spec/system/constructors/projects/new_project_wizard_spec.rb`'s `"acepta el presupuesto en pesos con formato local"` example. So this task does **not** consolidate `new`/`edit` onto one shared partial (that's a real pre-existing inconsistency between the two forms, but fixing it is out of scope for a drawer-mechanics migration) — it only wraps `new.html.erb`'s EXISTING field set in the drawer, leaving the full-page fallback and the shared `_form.html.erb` partial's own field list untouched.

Replace the full contents of `app/views/constructors/projects/new.html.erb`:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: "Nuevo proyecto", title: "Crear una obra", size: :lg)) do %>
      <%= form_with model: [:constructors, @project], html: { multipart: true } do |f| %>
        <div class="qb-field">
          <%= f.label :name, "Nombre del proyecto", class: "qb-label" %>
          <%= f.text_field :name, required: true, placeholder: 'Ej. Torre Palermo · Edificio Aurora', class: "qb-input" %>
        </div>
        <div class="qb-field">
          <%= f.label :client, "Cliente", class: "qb-label" %>
          <%= f.text_field :client, placeholder: 'Razón social', class: "qb-input" %>
        </div>
        <div class="qb-field">
          <%= f.label :description, "Descripción", class: "qb-label" %>
          <%= f.text_area :description, rows: 3, placeholder: 'Alcance de la obra, particularidades, notas para el equipo…', class: "qb-textarea" %>
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;">
          <div class="qb-field" style="margin-bottom:0;">
            <%= f.label :start_date, "Fecha de inicio", class: "qb-label" %>
            <%= f.date_field :start_date, class: "qb-input" %>
          </div>
          <div class="qb-field" style="margin-bottom:0;">
            <%= f.label :end_date, "Fecha de entrega", class: "qb-label" %>
            <%= f.date_field :end_date, class: "qb-input" %>
          </div>
        </div>
        <div class="qb-field">
          <%= f.label :budget_pesos, "Presupuesto estimado (ARS)", class: "qb-label" %>
          <%= f.text_field :budget_pesos, inputmode: 'decimal', placeholder: '1.500.000',
                value: (f.object.budget_cents.present? ? number_with_precision(f.object.budget_cents / 100.0, precision: 2, separator: ',', delimiter: '.') : nil),
                class: "qb-input" %>
          <p style="font-size:10.5px;color:var(--color-ink-4);margin-top:4px;">En pesos. Podés usar puntos de miles y coma decimal.</p>
        </div>
        <div class="qb-field">
          <%= f.label :status, "Estado inicial", class: "qb-label" %>
          <%= f.select :status, Project.status_options, { selected: 'planned' }, class: "qb-select" %>
        </div>

        <div style="margin-top:16px;padding-top:14px;border-top:1px solid var(--color-line);">
          <div style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;margin-bottom:8px;">Ubicación de la obra</div>
          <div class="qb-field">
            <%= f.label :location, "Domicilio", class: "qb-label" %>
            <%= f.text_field :location, placeholder: 'Ej. Av. Colón 1234, Mendoza', class: "qb-input", data: { project_map_target: "location" } %>
          </div>
          <div id="project-map" style="width:100%;height:220px;margin-top:10px;overflow:hidden;border-radius:var(--radius);border:1px solid var(--color-line);"
               data-controller="project-map" data-project-map-target="map">
            <%= f.hidden_field :latitude, data: { project_map_target: "latitude" } %>
            <%= f.hidden_field :longitude, data: { project_map_target: "longitude" } %>
          </div>
        </div>

        <div style="display:flex;align-items:center;gap:8px;margin-top:16px;">
          <%= render Qb::BtnComponent.new('Crear proyecto', variant: :primary, icon: :check, type: 'submit') %>
          <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
        </div>
      <% end %>
    <% end %>
  <% end %>
<% else %>
  <% content_for :qb_crumbs, [{label: 'Inicio'}, {label: 'Proyectos'}, {label: 'Nuevo'}].to_json %>

  <%# Formulario de un solo paso. La plantilla de etapas se aplica desde la obra
      ya creada ("Aplicar plantilla" en el header del proyecto): en el alta el
      usuario todavía no sabe qué etapas necesita. %>
  <div style="max-width:880px;margin:24px auto;border:1px solid var(--color-line);border-radius:8px;background:var(--color-bg-raised);overflow:hidden;">

    <%# Header %>
    <div style="display:flex;align-items:center;padding:14px 18px;border-bottom:1px solid var(--color-line);">
      <div>
        <div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-3);text-transform:uppercase;letter-spacing:0.8px;">Nuevo proyecto</div>
        <h2 style="margin:2px 0 0;font-size:18px;font-weight:600;">Crear una obra</h2>
      </div>
      <div style="flex:1;"></div>
      <%= render Qb::BtnComponent.new('', variant: :ghost, size: :sm, icon: :close, href: constructors_projects_path) %>
    </div>

    <%= form_with model: [:constructors, @project], html: { multipart: true, style: 'display:flex;flex-direction:column;' } do |f| %>
      <div style="padding:20px;">

        <%# Datos básicos %>
        <div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
            <label style="display:flex;flex-direction:column;gap:4px;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Nombre del proyecto</span>
              <%= f.text_field :name, required: true, placeholder: 'Ej. Torre Palermo · Edificio Aurora',
                                style: 'width:100%;height:34px;padding:0 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;outline:none;' %>
            </label>
            <label style="display:flex;flex-direction:column;gap:4px;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Cliente</span>
              <%= f.text_field :client, placeholder: 'Razón social',
                                style: 'width:100%;height:34px;padding:0 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;outline:none;' %>
            </label>
            <label style="display:flex;flex-direction:column;gap:4px;grid-column:1 / -1;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Descripción</span>
              <%= f.text_area :description, rows: 3, placeholder: 'Alcance de la obra, particularidades, notas para el equipo…',
                               style: 'width:100%;padding:8px 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;line-height:1.45;outline:none;resize:vertical;' %>
            </label>
            <label style="display:flex;flex-direction:column;gap:4px;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Fecha de inicio</span>
              <%= f.date_field :start_date,
                                style: 'width:100%;height:34px;padding:0 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;outline:none;' %>
            </label>
            <label style="display:flex;flex-direction:column;gap:4px;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Fecha de entrega</span>
              <%= f.date_field :end_date,
                                style: 'width:100%;height:34px;padding:0 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;outline:none;' %>
            </label>
            <label style="display:flex;flex-direction:column;gap:4px;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Presupuesto estimado (ARS)</span>
              <%= f.text_field :budget_pesos, inputmode: 'decimal', placeholder: '1.500.000',
                                  value: (f.object.budget_cents.present? ? number_with_precision(f.object.budget_cents / 100.0, precision: 2, separator: ',', delimiter: '.') : nil),
                                  style: 'width:100%;height:34px;padding:0 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;outline:none;font-family:var(--font-mono);' %>
              <span style="font-size:10.5px;color:var(--color-ink-4);">En pesos. Podés usar puntos de miles y coma decimal.</span>
            </label>
            <label style="display:flex;flex-direction:column;gap:4px;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Estado inicial</span>
              <%= f.select :status, Project.status_options, { selected: 'planned' },
                            style: 'width:100%;height:34px;padding:0 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;outline:none;' %>
            </label>
          </div>

          <%# Ubicación · el domicilio se escribe a mano en una línea y el mapa
              georreferencia la obra (lat/lng en hidden fields). Buscar una
              dirección en el geocoder del mapa también completa el domicilio. %>
          <div style="margin-top:20px;padding-top:16px;border-top:1px solid var(--color-line);">
            <div style="display:flex;align-items:baseline;gap:8px;margin-bottom:10px;">
              <div style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Ubicación de la obra</div>
              <div style="font-size:10.5px;color:var(--color-ink-4);">Buscá la dirección con la lupa del mapa o arrastrá el marcador</div>
            </div>
            <label style="display:flex;flex-direction:column;gap:4px;">
              <span style="font-size:11px;color:var(--color-ink-3);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:0.6px;">Domicilio</span>
              <%= f.text_field :location, placeholder: 'Ej. Av. Colón 1234, Mendoza',
                                style: 'width:100%;height:34px;padding:0 10px;border:1px solid var(--color-line);border-radius:5px;background:var(--color-bg);color:var(--color-ink);font-size:13px;outline:none;' %>
            </label>
            <div id="project-map"
                 style="width:100%;height:260px;margin-top:10px;overflow:hidden;border-radius:6px;border:1px solid var(--color-line);"
                 data-controller="project-map"
                 data-project-map-target="map">
              <%= f.hidden_field :latitude, data: { project_map_target: "latitude" } %>
              <%= f.hidden_field :longitude, data: { project_map_target: "longitude" } %>
            </div>
          </div>
        </div>

        <div style="font-size:11px;color:var(--color-ink-4);margin-top:18px;line-height:1.5;">
          Después de crear la obra podés aplicar una plantilla de etapas (la base o una tuya) desde el header del proyecto.
        </div>
      </div>

      <%# Footer %>
      <div style="display:flex;align-items:center;padding:14px 18px;border-top:1px solid var(--color-line);gap:8px;">
        <%= render Qb::BtnComponent.new('Cancelar', variant: :ghost, size: :sm, href: constructors_projects_path) %>
        <div style="flex:1;"></div>
        <button type="submit"
                style="display:inline-flex;align-items:center;gap:6px;height:28px;padding:0 10px;background:var(--color-accent);color:var(--color-accent-ink);border:1px solid var(--color-accent);border-radius:5px;font-size:12px;font-weight:500;cursor:pointer;">
          <%= render Qb::IconComponent.new(name: :check, size: 13) %>
          Crear proyecto
        </button>
      </div>
    <% end %>
  </div>
<% end %>
```

(This `<% else %>` branch is copied byte-for-byte from the file's current content — no field, style, or data attribute changes; only the new `<% if turbo_frame_request? %>` branch above it is new.)

- [ ] **Step 4: Manual smoke check**

Press ⌘N from anywhere → drawer opens with the create form. Fill it in, submit → drawer response includes the `redirect` stream action → browser navigates to the new project's page → flash shows "¡Obra creada correctamente!". Then visit `/constructors/projects/new` directly (full page) → same form renders inline, unchanged behavior for direct/no-JS access.

- [ ] **Step 5: Run the existing project creation specs**

Run: `bundle exec rspec spec/system/constructors/projects/new_project_wizard_spec.rb`
This spec doesn't assert on the resulting page, only on `project.budget_cents`/`location`/`latitude`/`longitude` after `click_button "Crear proyecto"` — it should keep passing unchanged. If it fails because the drawer's Turbo.visit races the assertion, add `expect(page).to have_current_path(constructors_project_path(project), wait: 5)` right after each `click_button "Crear proyecto"` call to make the test wait for the visit to land, matching the pattern already used in `landing_auth_entry_spec.rb`.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/constructors/projects_controller.rb app/views/constructors/projects/new.html.erb spec/system/constructors/projects/new_project_wizard_spec.rb
git rm app/views/constructors/projects/create.turbo_stream.erb
git commit -m "feat(drawer): migra alta de obra al drawer con Turbo.visit a la obra creada"
```

---

## Task 15: Proyecto — editar obra

**Files:**
- Modify: `app/controllers/constructors/projects_controller.rb`
- Modify: `app/views/constructors/projects/edit.html.erb`
- Modify: `app/views/constructors/projects/_form.html.erb`

**Interfaces:**
- Produces: `projects_controller#update` gains a `format.turbo_stream` success branch using `turbo_stream.refresh`.

- [ ] **Step 1: Add the turbo_stream branch to `update`**

Replace (currently lines 100-125), keeping the featured-image early-return branch untouched:

```ruby
    @project.assign_attributes(project_params)

    if persist_project_with_documents(@project)
      redirect_to constructors_project_path(@project), notice: "Obra actualizada correctamente."
    else
      @project_summary = @project.decorate
      flash.now[:alert] = "No pudimos guardar los cambios. Revisa los datos e inténtalo otra vez."
      render :edit, status: :unprocessable_entity
    end
  end
```

with:

```ruby
    @project.assign_attributes(project_params)

    if persist_project_with_documents(@project)
      respond_to do |format|
        format.turbo_stream do
          if request.variant.include?(:mobile)
            redirect_to constructors_project_path(@project), notice: "Obra actualizada correctamente."
          else
            render turbo_stream: turbo_stream.refresh
          end
        end
        format.html { redirect_to constructors_project_path(@project), notice: "Obra actualizada correctamente." }
      end
    else
      @project_summary = @project.decorate
      flash.now[:alert] = "No pudimos guardar los cambios. Revisa los datos e inténtalo otra vez."
      render :edit, status: :unprocessable_entity
    end
  end
```

- [ ] **Step 2: Add a drawer branch to `projects/edit.html.erb`**

Insert, as the FIRST lines of `app/views/constructors/projects/edit.html.erb` (before the existing `<div>` that today starts the file):

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(eyebrow: @project.decorate.code, title: "Editar obra", size: :lg)) do %>
      <%= render "form", project: @project %>
    <% end %>
  <% end %>
<% else %>
```

...and append `<% end %>` as the LAST line of the file, wrapping the existing two-column content (form + aside) unchanged as the full-page fallback. (Per spec §"decisión del asistente": the drawer version shows ONLY the core editable fields — no KPI aside, no image gallery preview — those stay exclusive to the full-page fallback.)

- [ ] **Step 3: Drop `_top` from the shared form partial**

In `app/views/constructors/projects/_form.html.erb`, replace:

```erb
<%= form_with model: [:constructors, project], data: { turbo_frame: "_top" } do |f| %>
```

with:

```erb
<%= form_with model: [:constructors, project] do |f| %>
```

(No `data:` override at all — the form is now always frame-scoped to whatever ambient frame it's rendered in: `"drawer"` when opened as a panel (both create and edit), or the top-level document when rendered as part of a full-page fallback body that ISN'T itself inside any frame — which is the case for both `projects/new.html.erb`'s and `projects/edit.html.erb`'s `else` branches, neither of which wraps its content in a `turbo_frame_tag`.)

- [ ] **Step 4: Manual smoke check**

From a project's header kebab menu, "Editar proyecto" → drawer opens with just the core fields (no aside). Change the name, save → drawer closes and the WHOLE page refreshes, header now shows the new name.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/constructors/projects_controller.rb app/views/constructors/projects/edit.html.erb app/views/constructors/projects/_form.html.erb
git commit -m "feat(drawer): migra edición de obra al drawer con refresh nativo de Turbo"
```

---

## Task 16: Gastos y Notas — nuevas vistas desktop + controllers

**Files:**
- Create: `app/views/constructors/expenses/new.html.erb`
- Create: `app/views/constructors/notes/new.html.erb`
- Modify: `app/controllers/constructors/expenses_controller.rb`
- Modify: `app/controllers/constructors/notes_controller.rb`

**Interfaces:**
- Produces: the first-ever DESKTOP `expenses#new`/`notes#new` templates (today only `*.html+mobile.erb` exist for these — confirmed via `ls app/views/constructors/{notes,expenses}/`). `expenses_controller#create` gains project-level `turbo_stream` handling (there was none before — confirmed bug). `notes_controller#create`'s existing project-level branch is simplified from a hand-rolled `project_notes_list` patch to the same `turbo_stream.refresh` idiom used everywhere else in this plan, for consistency; its stage-level path needs NO controller change (same redirect-follows-frame reasoning as Task 8's stage attachments).

- [ ] **Step 1: Create `expenses/new.html.erb`**

```erb
<%# Nuevo gasto — desktop. Antes sólo existía la modal inline
    (ExpenseModalComponent) y esta ruta sólo la servía Hotwire Native. Ahora
    es la vista real detrás del trigger "Registrar gasto" en cualquier
    contexto (proyecto u obra). %>
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(
          eyebrow: "Gastos",
          title: "Registrar nuevo gasto",
          subtitle: @stage ? "Se asocia a la etapa #{@stage.name}" : "Se asocia al proyecto",
          size: :md
        )) do %>
      <%= form_with model: @expense,
                    url: (@stage ? constructors_project_stage_expenses_path(@project, @stage) : constructors_project_expenses_path(@project)),
                    scope: :expense, multipart: true do |form| %>
        <% if @expense.errors.any? %>
          <div class="qb-form-error">
            <p style="font-weight:600;margin:0 0 4px;">No pudimos guardar el gasto:</p>
            <ul style="margin:0;padding-left:16px;">
              <% @expense.errors.full_messages.each do |message| %>
                <li><%= message %></li>
              <% end %>
            </ul>
          </div>
        <% end %>

        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">
          <div class="qb-field" style="margin-bottom:0;">
            <%= form.label :incurred_on, "Fecha", class: "qb-label" %>
            <%= form.date_field :incurred_on, value: @expense.incurred_on || Date.today, class: "qb-input" %>
          </div>
          <div class="qb-field" style="margin-bottom:0;">
            <%= form.label :amount_pesos, "Monto (ARS)", class: "qb-label" %>
            <%= form.text_field :amount_pesos, required: true, inputmode: "decimal", placeholder: "1.500,50",
                                value: @expense.amount_cents ? number_with_precision(@expense.amount_cents / 100.0, precision: 2, separator: ",", delimiter: ".") : nil, class: "qb-input" %>
          </div>
        </div>

        <div class="qb-field" style="margin-top:12px;">
          <%= form.label :category, "Categoría", class: "qb-label" %>
          <%= form.select :category, Constructors::Projects::ExpenseModalComponent::CATEGORY_OPTIONS, { selected: @expense.category, prompt: "Seleccionar categoría" }, class: "qb-select" %>
        </div>

        <div class="qb-field">
          <%= form.label :description, "Descripción", class: "qb-label" %>
          <%= form.text_area :description, rows: 2, value: @expense.description, class: "qb-textarea" %>
        </div>

        <div class="qb-field" style="margin-bottom:0;">
          <%= form.label :receipt, "Comprobante (JPG, PNG, PDF)", class: "qb-label" %>
          <%= form.file_field :receipt, accept: "image/jpeg,image/png,application/pdf",
                style: "display:block;font-size:12px;color:var(--color-ink-2);width:100%;" %>
        </div>

        <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
          <%= render Qb::BtnComponent.new('Guardar gasto', variant: :primary, icon: :plus, type: 'submit') %>
          <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
        </div>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

(No reachable `else` branch, same convention as `library/show.html.erb` — a direct full-page GET to this URL isn't a supported entry point; `expenses#new` is only ever reached as a frame-scoped drawer trigger or as Hotwire Native's bottom-sheet variant, per the existing controller comment.)

This task keeps `Constructors::Projects::ExpenseModalComponent::CATEGORY_OPTIONS` as the source of the category list rather than duplicating it — that constant stays put even after Task 17 trims the component's template, since the constant itself has nothing to do with modal chrome.

- [ ] **Step 2: Create `notes/new.html.erb`**

```erb
<%# Nueva nota — desktop. Antes sólo existía la modal inline
    (NoteModalComponent); esta ruta sólo la servía Hotwire Native. %>
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(
          eyebrow: "Notas",
          title: "Nueva nota",
          subtitle: @noteable.is_a?(ProjectStage) ? "Se asocia a la etapa #{@noteable.name}" : "Se asocia al proyecto",
          size: :md
        )) do %>
      <%= form_with model: @note,
                    url: (@noteable.is_a?(ProjectStage) ? constructors_project_stage_notes_path(@project, @noteable) : constructors_project_notes_path(@project)),
                    scope: :note do |form| %>
        <div class="qb-field">
          <%= form.label :title, "Título (opcional)", class: "qb-label" %>
          <%= form.text_field :title, class: "qb-input" %>
        </div>

        <div class="qb-field">
          <%= form.label :body, "Nota", class: "qb-label" %>
          <%= form.text_area :body, rows: 4, required: true, class: "qb-textarea" %>
        </div>

        <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
          <%= render Qb::BtnComponent.new('Guardar', variant: :primary, icon: :plus, type: 'submit') %>
          <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
        </div>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

- [ ] **Step 3: Add `expenses_controller#new`'s missing `authorize`-consistent turbo_stream branch to `create`**

Replace (currently lines 48-60):

```ruby
    def create
      @expense = @project.expenses.new(expense_params)
      @expense.project_stage = @stage if @stage
      @expense.author = current_user
      authorize @expense

      if @expense.save
        redirect_to redirect_path, notice: "Gasto registrado correctamente."
      else
        redirect_to redirect_path,
          alert: @expense.errors.full_messages.to_sentence
      end
    end
```

with:

```ruby
    def create
      @expense = @project.expenses.new(expense_params)
      @expense.project_stage = @stage if @stage
      @expense.author = current_user
      authorize @expense

      if @expense.save
        respond_to do |format|
          format.turbo_stream do
            if request.variant.include?(:mobile)
              redirect_to redirect_path, notice: "Gasto registrado correctamente."
            elsif @stage
              # Etapa: el form ya no fuerza _top, así que el redirect se sigue
              # como request de frame y stages#show repuebla "drawer" con el
              # detalle actualizado — mismo mecanismo que fotos/documentos.
              redirect_to redirect_path, notice: "Gasto registrado correctamente."
            else
              # Proyecto: no hay un único "detalle" al que volver (index,
              # resumen del proyecto…), así que refresh cierra el drawer y
              # refresca cualquiera de esas pantallas por igual.
              render turbo_stream: turbo_stream.refresh
            end
          end
          format.html { redirect_to redirect_path, notice: "Gasto registrado correctamente." }
        end
      else
        redirect_to redirect_path,
          alert: @expense.errors.full_messages.to_sentence
      end
    end
```

- [ ] **Step 4: Simplify `notes_controller#create`'s project-level branch to `turbo_stream.refresh`**

Replace (currently lines 18-49):

```ruby
    def create
      @note = @noteable.notes.new(note_params.merge(author: current_user))
      authorize @note

      if @note.save
        # Para notas del proyecto (resumen), respondemos turbo_stream para que
        # la modal cierre y la lista se refresque sin recargar la página.
        # Para notas de etapa, el flujo sigue siendo redirect (la drawer se
        # vuelve a abrir vía Turbo Frame al recargar la stage show).
        respond_to do |format|
          format.turbo_stream do
            # El target "project_notes_list" sólo existe en el show desktop;
            # en mobile la nota se crea desde una página propia, así que
            # respondemos con redirect + flash.
            if @noteable.is_a?(Project) && !request.variant.include?(:mobile)
              render turbo_stream: turbo_stream.update("project_notes_list",
                Constructors::Projects::NotesListComponent.new(
                  notes: @project.notes.recent_first.includes(:author),
                  noteable: @project,
                  project: @project
                ))
            else
              redirect_to redirect_path, notice: "Nota agregada correctamente."
            end
          end
          format.html { redirect_to redirect_path, notice: "Nota agregada correctamente." }
        end
      else
        redirect_to redirect_path,
          alert: @note.errors.full_messages.to_sentence
      end
    end
```

with:

```ruby
    def create
      @note = @noteable.notes.new(note_params.merge(author: current_user))
      authorize @note

      if @note.save
        # Etapa: el form ya no fuerza _top, así que el redirect se sigue como
        # request de frame y stages#show repuebla "drawer" con el detalle
        # actualizado — mismo mecanismo que fotos/documentos/gastos de etapa.
        # Proyecto: no hay un único "detalle" al que volver, así que refresh
        # cierra el drawer y refresca la página actual (index, resumen…).
        respond_to do |format|
          format.turbo_stream do
            if request.variant.include?(:mobile) || @noteable.is_a?(ProjectStage)
              redirect_to redirect_path, notice: "Nota agregada correctamente."
            else
              render turbo_stream: turbo_stream.refresh
            end
          end
          format.html { redirect_to redirect_path, notice: "Nota agregada correctamente." }
        end
      else
        redirect_to redirect_path,
          alert: @note.errors.full_messages.to_sentence
      end
    end
```

- [ ] **Step 5: Run existing note/expense specs**

Run: `bundle exec rspec spec/requests/constructors/notes_spec.rb spec/requests/constructors/expenses_spec.rb` (or wherever the existing request specs for these controllers live — locate with `grep -rl "NotesController\|ExpensesController\|constructors_project_notes_path\|constructors_project_expenses_path" spec/requests`). Update any assertion that checked for the old `turbo_stream.update("project_notes_list", ...)` body to instead check for `turbo-stream action="refresh"`.

- [ ] **Step 6: Commit**

```bash
git add app/views/constructors/expenses/new.html.erb app/views/constructors/notes/new.html.erb app/controllers/constructors/expenses_controller.rb app/controllers/constructors/notes_controller.rb
git commit -m "feat(drawer): agrega vistas desktop de gasto/nota y cierra el bug de notas de etapa sin turbo_stream"
```

---

## Task 17: Gastos y Notas — reconectar triggers, borrar modales inline

**Files:**
- Modify: `app/components/constructors/projects/planning/stage_detail_component.html.erb`
- Modify: `app/components/constructors/projects/header_component.html.erb`
- Delete: `app/components/constructors/projects/expense_modal_component.rb`
- Delete: `app/components/constructors/projects/expense_modal_component.html.erb`
- Delete: `app/components/constructors/projects/note_modal_component.rb`
- Delete: `app/components/constructors/projects/note_modal_component.html.erb`

**Interfaces:**
- Consumes: `Task 16`'s new `expenses#new`/`notes#new` routes and views.
- Removes: `Constructors::Projects::ExpenseModalComponent`, `Constructors::Projects::NoteModalComponent` and every reference to them (both are now fully superseded by the frame-driven views).

- [ ] **Step 1: Replace the Gastos tab in `stage_detail_component.html.erb`**

Replace (currently lines 152-174):

```erb
  <%# Tab: Gastos %>
  <% tp.with_tab(label: "Gastos", count: stage.object.expenses.size) do %>
    <div data-controller="qb--modal">
      <% if can_manage_content? %>
        <div class="sd-tab-actions">
          <%= render Qb::BtnComponent.new('Nuevo gasto', variant: :primary, size: :xs, icon: :plus,
                data: { action: 'click->qb--modal#open' }) %>
        </div>
      <% end %>
      <% if stage.object.expenses.empty? %>
        <div class="sd-list"><div class="sd-list-empty">Todavía no hay gastos registrados en esta etapa.</div></div>
      <% else %>
        <%= render Constructors::Projects::ExpensesListComponent.new(
              expenses: stage.object.expenses.recent_first,
              project: project,
              stage: stage.object,
              bare: true) %>
      <% end %>
      <% if can_manage_content? %>
        <%= render Constructors::Projects::ExpenseModalComponent.new(project: project, stage: stage.object) %>
      <% end %>
    </div>
  <% end %>
```

with:

```erb
  <%# Tab: Gastos %>
  <% tp.with_tab(label: "Gastos", count: stage.object.expenses.size) do %>
    <% if can_manage_content? %>
      <div class="sd-tab-actions">
        <%= render Qb::BtnComponent.new('Nuevo gasto', variant: :primary, size: :xs, icon: :plus,
              href: new_constructors_project_stage_expense_path(project, stage),
              data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' }) %>
      </div>
    <% end %>
    <% if stage.object.expenses.empty? %>
      <div class="sd-list"><div class="sd-list-empty">Todavía no hay gastos registrados en esta etapa.</div></div>
    <% else %>
      <%= render Constructors::Projects::ExpensesListComponent.new(
            expenses: stage.object.expenses.recent_first,
            project: project,
            stage: stage.object,
            bare: true) %>
    <% end %>
  <% end %>
```

- [ ] **Step 2: Replace the Notas tab**

Replace (currently lines 177-198):

```erb
  <%# Tab: Notas %>
  <% tp.with_tab(label: "Notas", count: stage.object.notes.size) do %>
    <div data-controller="qb--modal">
      <% if can_manage_content? %>
        <div class="sd-tab-actions">
          <%= render Qb::BtnComponent.new('Nueva nota', variant: :primary, size: :xs, icon: :plus,
                data: { action: 'click->qb--modal#open' }) %>
        </div>
      <% end %>
      <% if stage.object.notes.empty? %>
        <div class="sd-list"><div class="sd-list-empty">Todavía no hay notas en esta etapa.</div></div>
      <% else %>
        <%= render Constructors::Projects::NotesListComponent.new(
              notes: stage.object.notes.recent_first.includes(:author),
              noteable: stage.object,
              project: project,
              bare: true) %>
      <% end %>
      <% if can_manage_content? %>
        <%= render Constructors::Projects::NoteModalComponent.new(project: project, stage: stage.object) %>
      <% end %>
    </div>
  <% end %>
```

with:

```erb
  <%# Tab: Notas %>
  <% tp.with_tab(label: "Notas", count: stage.object.notes.size) do %>
    <% if can_manage_content? %>
      <div class="sd-tab-actions">
        <%= render Qb::BtnComponent.new('Nueva nota', variant: :primary, size: :xs, icon: :plus,
              href: new_constructors_project_stage_note_path(project, stage),
              data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' }) %>
      </div>
    <% end %>
    <% if stage.object.notes.empty? %>
      <div class="sd-list"><div class="sd-list-empty">Todavía no hay notas en esta etapa.</div></div>
    <% else %>
      <%= render Constructors::Projects::NotesListComponent.new(
            notes: stage.object.notes.recent_first.includes(:author),
            noteable: stage.object,
            project: project,
            bare: true) %>
    <% end %>
  <% end %>
```

- [ ] **Step 3: Reconnect "Registrar gasto" in `header_component.html.erb`**

Replace (currently lines 53-70):

```erb
        <div class="qb-proj-actions" style="display:flex;gap:8px;" data-controller="qb--modal">
          <%= render Qb::MenuComponent.new(items: [
                { label: 'Exportar etapas (CSV)', icon: :download,
                  href: constructors_project_stages_path(project, format: :csv),
                  title: 'Descargar etapas del proyecto (CSV)' },
                ({ label: 'Editar proyecto', icon: :edit,
                   href: edit_constructors_project_path(project) } if can_edit_project?),
                ({ divider: true } if can_destroy_project?),
                ({ label: 'Eliminar obra', icon: :trash, danger: true,
                   href: constructors_project_path(project),
                   data: { turbo_method: :delete,
                           turbo_confirm: "¿Eliminar la obra \"#{project.name}\"? Se borrarán sus etapas, documentos y gastos. Esta acción no se puede deshacer." } } if can_destroy_project?),
              ]) %>
          <% if can_manage_content? %>
            <%= render Qb::BtnComponent.new('Registrar gasto', variant: :primary, size: :sm, icon: :plus,
                                            data: { action: 'click->qb--modal#open' }) %>
            <%= render Constructors::Projects::ExpenseModalComponent.new(project: project) %>
          <% end %>
        </div>
```

with:

```erb
        <div class="qb-proj-actions" style="display:flex;gap:8px;">
          <%= render Qb::MenuComponent.new(items: [
                { label: 'Exportar etapas (CSV)', icon: :download,
                  href: constructors_project_stages_path(project, format: :csv),
                  title: 'Descargar etapas del proyecto (CSV)' },
                ({ label: 'Editar proyecto', icon: :edit,
                   href: edit_constructors_project_path(project),
                   data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' } } if can_edit_project?),
                ({ divider: true } if can_destroy_project?),
                ({ label: 'Eliminar obra', icon: :trash, danger: true,
                   href: constructors_project_path(project),
                   data: { turbo_method: :delete,
                           turbo_confirm: "¿Eliminar la obra \"#{project.name}\"? Se borrarán sus etapas, documentos y gastos. Esta acción no se puede deshacer." } } if can_destroy_project?),
              ]) %>
          <% if can_manage_content? %>
            <%= render Qb::BtnComponent.new('Registrar gasto', variant: :primary, size: :sm, icon: :plus,
                  href: new_constructors_project_expense_path(project),
                  data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' }) %>
          <% end %>
        </div>
```

(`Qb::MenuComponent`'s items already support arbitrary `data:` per item per its existing API — confirmed via its use elsewhere with `turbo_method`/`turbo_confirm`; verify `href`+`data` on a plain, non-destructive item renders as a normal `link_to` with those data attributes before relying on this, reading `app/components/qb/menu_component.html.erb` if anything looks off.)

- [ ] **Step 4: Delete the two now-unused modal components**

```bash
git rm app/components/constructors/projects/expense_modal_component.rb
git rm app/components/constructors/projects/expense_modal_component.html.erb
git rm app/components/constructors/projects/note_modal_component.rb
git rm app/components/constructors/projects/note_modal_component.html.erb
```

- [ ] **Step 5: Sweep for any remaining reference**

Run: `grep -rn "ExpenseModalComponent\|NoteModalComponent" app/ spec/`
Expected: no matches (the `CATEGORY_OPTIONS` constant reference added in Task 16 Step 1 must be updated too if this task runs — since the component class no longer exists, move `CATEGORY_OPTIONS` to live directly in `app/views/constructors/expenses/new.html.erb` as a local array, or better, define it as a small `Expense::CATEGORY_OPTIONS` constant on the model if one doesn't already exist there — check `app/models/expense.rb` first for an existing categories-with-labels helper before adding a new one).

- [ ] **Step 6: Manual smoke check**

From a project header, "Registrar gasto" → drawer opens, project-scoped → save → drawer closes, page refreshes. From a stage detail's Gastos tab, "Nuevo gasto" → drawer swaps to the stage-scoped form → save → drawer returns to the refreshed stage detail. Same for Notas.

- [ ] **Step 7: Commit**

```bash
git add app/components/constructors/projects/planning/stage_detail_component.html.erb app/components/constructors/projects/header_component.html.erb app/views/constructors/expenses/new.html.erb
git rm app/components/constructors/projects/expense_modal_component.rb app/components/constructors/projects/expense_modal_component.html.erb app/components/constructors/projects/note_modal_component.rb app/components/constructors/projects/note_modal_component.html.erb
git commit -m "feat(drawer): conecta triggers de gasto/nota a las vistas nuevas, borra las modales inline"
```

---

## Task 18: Invitar miembro — re-skin (excepción documentada, sigue inline)

**Files:**
- Modify: `app/components/constructors/projects/overview/members_panel_component.html.erb`
- Modify: `app/components/constructors/projects/overview/invite_member_modal_component.html.erb` → rename to `invite_member_drawer_component.html.erb`
- Modify: `app/components/constructors/projects/overview/invite_member_modal_component.rb` → rename to `invite_member_drawer_component.rb`

**Interfaces:**
- Uses the CLICK-DRIVEN mode of `qb--drawer` from Task 2 (no `frame` target — this stays a self-contained inline instance since `project_memberships` has no `:new` route; adding one is explicitly out of scope for this migration).

- [ ] **Step 1: Rename the component**

```bash
git mv app/components/constructors/projects/overview/invite_member_modal_component.rb app/components/constructors/projects/overview/invite_member_drawer_component.rb
git mv app/components/constructors/projects/overview/invite_member_modal_component.html.erb app/components/constructors/projects/overview/invite_member_drawer_component.html.erb
```

In `invite_member_drawer_component.rb`, rename the class from `Constructors::Projects::Overview::InviteMemberModalComponent` to `Constructors::Projects::Overview::InviteMemberDrawerComponent`, keeping its `initialize`/private methods identical.

- [ ] **Step 2: Re-skin the template using `Qb::DrawerComponent`'s chrome classes, keeping it click-driven and inline**

Replace the full contents of `invite_member_drawer_component.html.erb`:

```erb
<div class="qb-drawer-shell" data-qb--drawer-target="dialog"
     data-action="click->qb--drawer#backdrop keydown@window->qb--drawer#keydown">
  <div class="qb-drawer-backdrop"></div>
  <%= render(Qb::DrawerComponent.new(eyebrow: "Equipo", title: "Invitar miembro a la obra", subtitle: "El usuario ya tiene que existir en la plataforma.", size: :md)) do %>
    <%= form_with url: constructors_project_project_memberships_path(project), method: :post, scope: :project_membership do |f| %>
      <div class="qb-field">
        <%= f.label :user_id, "Selecciona un usuario", class: "qb-label" %>
        <%= f.select :user_id, candidate_user_options, { include_blank: '— Elegí un usuario —' }, required: true, class: "qb-select" %>
      </div>

      <div class="qb-field">
        <%= f.label :role, "Rol en la obra", class: "qb-label" %>
        <%= f.select :role, role_options, { selected: 'editor' }, required: true, class: "qb-select" %>
      </div>

      <%# Qué significa cada rol: elegirlo a ciegas era la forma más fácil de
          dar de más. El dueño no está en la lista — no se invita. %>
      <ul style="margin:0;padding:10px 12px;list-style:none;display:flex;flex-direction:column;gap:6px;background:var(--color-bg-sunken);border-radius:5px;">
        <% role_hints.each do |label, hint| %>
          <li style="font-size:11px;color:var(--color-ink-3);line-height:1.45;">
            <strong style="color:var(--color-ink-2);"><%= label %></strong> · <%= hint %>
          </li>
        <% end %>
      </ul>

      <div style="display:flex;align-items:center;gap:8px;margin-top:14px;">
        <%= render Qb::BtnComponent.new('Agregar miembro', variant: :primary, icon: :plus, type: 'submit') %>
        <%= render Qb::BtnComponent.new('Cancelar', variant: :secondary, data: { action: 'click->qb--drawer#close' }) %>
      </div>
    <% end %>
  <% end %>
</div>
```

- [ ] **Step 3: Update `members_panel_component.html.erb`'s trigger and wrapper controller**

Replace (currently lines 1-11):

```erb
<div data-controller="qb--modal">
  <%= render Qb::SectionHeadComponent.new(
        title: 'Accesos a la obra',
        subtitle: 'Usuarios de QuickBuild que pueden entrar a esta obra, y con qué permisos') do |c| %>
    <% if can_manage? %>
      <% c.with_right do %>
        <%= render Qb::BtnComponent.new('Invitar miembro', variant: :primary, size: :xs, icon: :plus,
              data: { action: 'click->qb--modal#open' }) %>
      <% end %>
    <% end %>
  <% end %>
```

with:

```erb
<div data-controller="qb--drawer">
  <%= render Qb::SectionHeadComponent.new(
        title: 'Accesos a la obra',
        subtitle: 'Usuarios de QuickBuild que pueden entrar a esta obra, y con qué permisos') do |c| %>
    <% if can_manage? %>
      <% c.with_right do %>
        <%= render Qb::BtnComponent.new('Invitar miembro', variant: :primary, size: :xs, icon: :plus,
              data: { action: 'click->qb--drawer#open' }) %>
      <% end %>
    <% end %>
  <% end %>
```

And replace the final component render call (currently line 54):

```erb
    <%= render Constructors::Projects::Overview::InviteMemberModalComponent.new(project: project) %>
```

with:

```erb
    <%= render Constructors::Projects::Overview::InviteMemberDrawerComponent.new(project: project) %>
```

- [ ] **Step 4: Manual smoke check**

From a project's Overview/team panel, "Invitar miembro" → panel slides in from the right (same animation/chrome as every other drawer, but purely client-side — no network request until submit). Escape/backdrop closes it. Submitting adds the member (unchanged server behavior).

- [ ] **Step 5: Commit**

```bash
git add app/components/constructors/projects/overview/members_panel_component.html.erb app/components/constructors/projects/overview/invite_member_drawer_component.rb app/components/constructors/projects/overview/invite_member_drawer_component.html.erb
git rm app/components/constructors/projects/overview/invite_member_modal_component.rb app/components/constructors/projects/overview/invite_member_modal_component.html.erb
git commit -m "feat(drawer): reskin de invitar miembro (excepción inline documentada)"
```

---

## Task 19: Biblioteca — re-skin del visor de documentos

**Files:**
- Modify: `app/views/constructors/library/show.html.erb`
- Modify: `app/views/constructors/library/index.html.erb`

**Interfaces:**
- Consumes: `Qb::DrawerComponent`'s `custom_header` slot (same reasoning as Task 10 — this view has its own rich header, not a plain eyebrow/title).

- [ ] **Step 1: Convert `library/show.html.erb`**

Replace (currently lines 25-94):

```erb
<% if turbo_frame_request? %>
  <%= turbo_frame_tag "project_modal" do %>
    <div data-controller="qb--drawer">
      <div data-qb--drawer-target="dialog" role="dialog" aria-modal="true"
           class="hidden"
           data-action="click->qb--drawer#backdrop keydown@window->qb--drawer#keydown"
           style="display:none;position:fixed;inset:0;z-index:50;background:rgba(0,0,0,0.40);justify-content:flex-end;">
        <div data-qb--drawer-target="panel"
             style="position:relative;width:880px;max-width:100vw;background:var(--color-bg);border-left:1px solid var(--color-line);display:flex;flex-direction:column;overflow:hidden;height:100vh;">

          <%# Header %>
          <div style="padding:14px 20px;border-bottom:1px solid var(--color-line);display:flex;align-items:center;gap:10px;">
            <button type="button" data-action="click->qb--drawer#close" aria-label="Cerrar"
                    style="background:transparent;border:none;color:var(--color-ink-3);cursor:pointer;padding:4px;">
              <%= render Qb::IconComponent.new(name: :x, size: 16) %>
            </button>
            <div style="flex:1;min-width:0;">
              <div style="display:flex;align-items:center;gap:8px;margin-bottom:2px;">
                <span style="font-size:10px;padding:3px 4px;background:var(--color-bg-sunken);border:1px solid var(--color-line);border-radius:3px;color:var(--color-ink-3);font-family:var(--font-mono);text-align:center;min-width:36px;display:inline-block;"><%= ext %></span>
                <span class="qb-mono" style="font-size:10px;color:var(--color-ink-4);"><%= location_text %></span>
              </div>
              <h2 style="margin:0;font-size:15px;font-weight:600;color:var(--color-ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"><%= @document.file_filename %></h2>
            </div>
            <%= link_to "Descargar", file_url,
                  style: 'display:inline-flex;align-items:center;gap:6px;height:28px;padding:0 10px;background:var(--color-bg-raised);color:var(--color-ink);border:1px solid var(--color-line-2);border-radius:5px;font-size:12px;font-weight:500;text-decoration:none;' %>
            <%= link_to "Abrir en pestaña", file_url, target: '_blank', rel: 'noopener',
                  data: { turbo_frame: '_top' },
                  style: 'display:inline-flex;align-items:center;gap:6px;height:28px;padding:0 10px;background:var(--color-accent);color:var(--color-accent-ink);border:1px solid var(--color-accent);border-radius:5px;font-size:12px;font-weight:500;text-decoration:none;' %>
          </div>

          <%# Metadata strip %>
          <div style="padding:10px 20px;border-bottom:1px solid var(--color-line);background:var(--color-bg-raised);display:grid;grid-template-columns:repeat(3, 1fr);gap:16px;font-size:12px;">
            <div>
              <div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);text-transform:uppercase;letter-spacing:0.7px;margin-bottom:2px;">Tamaño</div>
              <div class="qb-mono qb-tnum"><%= number_to_human_size(@document.file_byte_size) %></div>
            </div>
            <div>
              <div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);text-transform:uppercase;letter-spacing:0.7px;margin-bottom:2px;">Tipo</div>
              <div><%= blob.content_type %></div>
            </div>
            <div>
              <div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);text-transform:uppercase;letter-spacing:0.7px;margin-bottom:2px;">Subido</div>
              <div class="qb-mono"><%= qb_fmt_datetime_short(@document.uploaded_at) %></div>
            </div>
          </div>

          <%# Viewer %>
          <div style="flex:1;overflow:auto;background:var(--color-bg-sunken);display:flex;align-items:center;justify-content:center;">
            <% if is_image %>
              <img src="<%= file_url %>" alt="<%= @document.file_filename %>"
                   style="max-width:100%;max-height:100%;object-fit:contain;background:var(--color-bg);border:1px solid var(--color-line);">
            <% elsif is_pdf %>
              <iframe src="<%= file_url %>" title="<%= @document.file_filename %>"
                      style="width:100%;height:100%;border:none;background:white;"></iframe>
            <% else %>
              <div style="padding:40px;text-align:center;color:var(--color-ink-3);font-size:13px;max-width:380px;">
                <%= render Qb::IconComponent.new(name: :docs, size: 32, style: 'opacity:0.5;margin-bottom:10px;') %>
                <div style="font-size:14px;color:var(--color-ink-2);margin-bottom:4px;">No se puede previsualizar este archivo</div>
                <div>Usá <strong>Descargar</strong> o <strong>Abrir en pestaña</strong> para verlo.</div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  <% end %>
<% end %>
```

with:

```erb
<% if turbo_frame_request? %>
  <% content_for(:drawer) do %>
    <%= render(Qb::DrawerComponent.new(size: :xl)) do |d| %>
      <% d.with_custom_header do %>
        <div class="qb-drawer-header">
          <button type="button" class="qb-drawer-close" data-action="click->qb--drawer#close" aria-label="Cerrar">
            <%= render Qb::IconComponent.new(name: :x, size: 16) %>
          </button>
          <div class="qb-drawer-header-main">
            <div style="display:flex;align-items:center;gap:8px;margin-bottom:2px;">
              <span style="font-size:10px;padding:3px 4px;background:var(--color-bg-sunken);border:1px solid var(--color-line);border-radius:3px;color:var(--color-ink-3);font-family:var(--font-mono);text-align:center;min-width:36px;display:inline-block;"><%= ext %></span>
              <span class="qb-mono" style="font-size:10px;color:var(--color-ink-4);"><%= location_text %></span>
            </div>
            <h2 class="qb-drawer-title" style="font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"><%= @document.file_filename %></h2>
          </div>
          <%= link_to "Descargar", file_url,
                style: 'display:inline-flex;align-items:center;gap:6px;height:28px;padding:0 10px;background:var(--color-bg-raised);color:var(--color-ink);border:1px solid var(--color-line-2);border-radius:5px;font-size:12px;font-weight:500;text-decoration:none;flex-shrink:0;' %>
          <%= link_to "Abrir en pestaña", file_url, target: '_blank', rel: 'noopener',
                style: 'display:inline-flex;align-items:center;gap:6px;height:28px;padding:0 10px;background:var(--color-accent);color:var(--color-accent-ink);border:1px solid var(--color-accent);border-radius:5px;font-size:12px;font-weight:500;text-decoration:none;flex-shrink:0;' %>
        </div>
      <% end %>

      <%# Metadata strip %>
      <div style="margin:-18px -20px 18px;padding:10px 20px;border-bottom:1px solid var(--color-line);background:var(--color-bg-raised);display:grid;grid-template-columns:repeat(3, 1fr);gap:16px;font-size:12px;">
        <div>
          <div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);text-transform:uppercase;letter-spacing:0.7px;margin-bottom:2px;">Tamaño</div>
          <div class="qb-mono qb-tnum"><%= number_to_human_size(@document.file_byte_size) %></div>
        </div>
        <div>
          <div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);text-transform:uppercase;letter-spacing:0.7px;margin-bottom:2px;">Tipo</div>
          <div><%= blob.content_type %></div>
        </div>
        <div>
          <div style="font-size:10px;font-family:var(--font-mono);color:var(--color-ink-4);text-transform:uppercase;letter-spacing:0.7px;margin-bottom:2px;">Subido</div>
          <div class="qb-mono"><%= qb_fmt_datetime_short(@document.uploaded_at) %></div>
        </div>
      </div>

      <%# Viewer %>
      <div style="margin:-18px -20px;height:calc(100% + 36px);overflow:auto;background:var(--color-bg-sunken);display:flex;align-items:center;justify-content:center;">
        <% if is_image %>
          <img src="<%= file_url %>" alt="<%= @document.file_filename %>"
               style="max-width:100%;max-height:100%;object-fit:contain;background:var(--color-bg);border:1px solid var(--color-line);">
        <% elsif is_pdf %>
          <iframe src="<%= file_url %>" title="<%= @document.file_filename %>"
                  style="width:100%;height:100%;border:none;background:white;"></iframe>
        <% else %>
          <div style="padding:40px;text-align:center;color:var(--color-ink-3);font-size:13px;max-width:380px;">
            <%= render Qb::IconComponent.new(name: :docs, size: 32, style: 'opacity:0.5;margin-bottom:10px;') %>
            <div style="font-size:14px;color:var(--color-ink-2);margin-bottom:4px;">No se puede previsualizar este archivo</div>
            <div>Usá <strong>Descargar</strong> o <strong>Abrir en pestaña</strong> para verlo.</div>
          </div>
        <% end %>
      </div>
    <% end %>
  <% end %>
<% end %>
```

(The metadata strip and viewer use negative margins to bleed to the edges of `.qb-drawer-body`'s own `18px 20px` padding, since this view wants a full-bleed image/PDF viewer rather than the padded default body — same visual result as before, now expressed relative to the shared component's padding instead of a bespoke panel.)

- [ ] **Step 2: Rename the trigger and delete the placeholder in `library/index.html.erb`**

At line 94, replace `data: { turbo_frame: 'project_modal' })` with `data: { turbo_frame: 'drawer', action: 'click->qb--drawer#open' })`. Delete the trailing bare `turbo_frame_tag "project_modal"` at line 126.

- [ ] **Step 3: Manual smoke check**

From Biblioteca, click a document → drawer opens (880px) showing the image/PDF viewer full-bleed with the metadata strip. Close it, click another → same panel swaps content without a jarring re-mount (the shell stays put across the click, only the frame content swaps).

- [ ] **Step 4: Commit**

```bash
git add app/views/constructors/library/show.html.erb app/views/constructors/library/index.html.erb
git commit -m "feat(drawer): reskin del visor de biblioteca"
```

---

## Task 20: Limpieza final — borrar `qb--modal`, barrido de referencias sueltas

**Files:**
- Delete: `app/javascript/controllers/qb/modal_controller.js`
- Modify: any file the sweep in Step 1 turns up

- [ ] **Step 1: Sweep for anything still referencing the old names**

Run each of these and confirm zero matches (outside `*.html+mobile.erb`, which is explicitly out of scope):

```bash
grep -rln "qb--modal" app/ --include="*.erb" --include="*.rb" --include="*.js" | grep -v "html+mobile"
grep -rln "project_modal\|\"stage_detail\"\|'stage_detail'" app/ --include="*.erb" --include="*.rb" | grep -v "html+mobile"
```

If either command returns any file, open it and finish that rename/removal before proceeding — every occurrence should already have been handled by Tasks 6–19; this step exists to catch anything the manual `sed -n`/read-then-edit process in earlier tasks missed (e.g. a stray comment, a spec fixture, a second reference on a line that wasn't quoted in this plan).

- [ ] **Step 2: Delete the old modal controller**

```bash
git rm app/javascript/controllers/qb/modal_controller.js
```

- [ ] **Step 3: Confirm Stimulus's manifest doesn't reference it explicitly**

Run: `grep -rn "modal_controller\|qb/modal" app/javascript/`
Expected: no matches (Stimulus's `pin_all_from "app/javascript/controllers", under: "controllers"` auto-registers every file in that directory by filename — deleting the file is sufficient, there's no separate manifest entry to remove).

- [ ] **Step 4: Full grep sweep for the two renamed "Modal" component class names**

```bash
grep -rln "ExpenseModalComponent\|NoteModalComponent\|UploadModalComponent\|NewListModalComponent\|InviteMemberModalComponent" app/ spec/
```

Expected: no matches (all four should already be renamed by Tasks 9, 11, 17, 18). Fix any straggler found.

- [ ] **Step 5: Commit**

```bash
git rm app/javascript/controllers/qb/modal_controller.js
git commit -m "chore(drawer): elimina el controller qb--modal, ya sin referencias"
```

---

## Task 21: Verificación completa

**Files:** none (verification only)

- [ ] **Step 1: Rubocop**

Run: `bundle exec rubocop -a`
Fix any offense the auto-corrector can't handle by hand. Re-run until clean.

- [ ] **Step 2: Full test suite**

Run: `bundle exec rspec`
Expected: 0 failures. Pay particular attention to:
- Any spec that asserted on `project_modal`/`stage_detail` DOM ids directly (should now assert on `"drawer"`).
- Any spec that asserted on `qb--modal`-specific classes/attributes (`data-qb--modal-target`, `hidden` class toggling via inline `style.display`) — these should now assert on `.qb-drawer-open`/`.qb-drawer-shell` instead, or be removed if they were purely testing the old mechanism.
- `spec/system/constructors/projects/new_project_wizard_spec.rb` (Task 14).
- `spec/system/landing_auth_entry_spec.rb` — unrelated to this migration (marketing login modal, different `qb--modal`... actually check: this spec references `turbo_frame#login_modal`, a DIFFERENT frame unrelated to the constructor `qb--modal` controller being deleted here — confirm `app/views/sessions/_login_form.html.erb`'s login modal is part of the MARKETING layout, not `Constructors::`, and therefore explicitly out of scope for this whole migration (CLAUDE.md: "the public/marketing layout... keeps its own design"). Do not touch it; just confirm this spec still passes untouched.

- [ ] **Step 3: Route/drawer smoke sweep**

Manually (or via a quick throwaway script) hit every one of these desktop URLs as both a normal GET and a Turbo-Frame-scoped GET (`curl -H "Turbo-Frame: drawer"`) while signed in, confirming a 200 and the expected panel/fallback content for each:
- `/constructors/projects/new`, `/constructors/projects/:id/edit`
- `/constructors/projects/:id/stages/new`, `/constructors/projects/:id/stages/:id/edit`, `/constructors/projects/:id/stages/:id` (view)
- `/constructors/projects/:id/stages/:id/images/new`, `/constructors/projects/:id/stages/:id/documents/new`
- `/constructors/projects/:id/material_lists/new`, `/constructors/projects/:id/material_lists/:id/edit`, `/constructors/projects/:id/material_lists/:id` (show)
- `/constructors/projects/:id/blueprints/new`
- `/constructors/projects/:id/people/new`, `/constructors/projects/:id/people/:id/edit`
- `/constructors/people/:id/edit`
- `/constructors/projects/:id/expenses/new`, `/constructors/projects/:id/stages/:id/expenses/new`
- `/constructors/projects/:id/notes/new`, `/constructors/projects/:id/stages/:id/notes/new`
- `/constructors/biblioteca/:id`

- [ ] **Step 4: Browser walkthrough**

Run `bin/dev`, sign in, and manually click through the golden path once end to end: create a project (⌘N) → land on it → apply a stage template → open a stage card → edit it in place → upload a photo → add a note → add a gasto → create a material list from the stage → mark it approved → invite a member → edit the project → edit a person's ficha → open a document from Biblioteca. Confirm every panel slides in/out smoothly, no duplicate-id console warnings, no dead modal chrome left visible anywhere, and mobile (resize to a phone width, or open any `*+mobile` URL directly) is completely unaffected.

- [ ] **Step 5: Final commit (if verification produced fixes)**

```bash
git add -A
git commit -m "fix(drawer): ajustes de verificación post-migración"
```
