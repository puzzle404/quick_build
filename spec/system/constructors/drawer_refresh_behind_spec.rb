# frozen_string_literal: true

require "rails_helper"

# Revisión final: el refresco de la página de atrás tras un guardado del
# drawer (qb--drawer) también tiene que cubrir los links turbo_method que
# apuntan al drawer (Turbo arma ese form fuera del frame, en el <body>), y
# NO tiene que meterse con forms del drawer que navegan afuera (_top).
RSpec.describe "Refresco de atrás tras acciones en el drawer", type: :system, js: true do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before { sign_in_user(owner) }

  it "«Marcar completada» actualiza la tarjeta de la etapa detrás del drawer" do
    stage = create(:project_stage, project: project, name: "Replanteo", progress: 40)
    visit constructors_project_path(project, drawer: constructors_project_stage_path(project, stage))
    expect(page).to have_css(".qb-drawer-panel", text: "Replanteo", wait: 5)
    expect(page).to have_css("#card_project_stage_#{stage.id}", text: "40%")

    within(".qb-drawer-panel") { click_on "Marcar completada" }

    expect(page).to have_css("#card_project_stage_#{stage.id}", text: "100%", wait: 5)
    expect(stage.reload.progress).to eq(100)
  end

  it "un form del drawer que navega afuera (_top) no dispara el refresco de atrás" do
    stage = create(:project_stage, project: project, name: "Replanteo")
    visit constructors_project_path(project, drawer: constructors_project_stage_path(project, stage))
    expect(page).to have_css(".qb-drawer-panel", text: "Replanteo", wait: 5)

    page.execute_script(<<~JS)
      // window.Turbo es un namespace de módulo (no se puede parchear): se
      // registra cualquier visita de Turbo que arranque.
      window.__visits = []
      document.addEventListener("turbo:visit", (event) => window.__visits.push(event.detail.url))
      const form = document.createElement("form")
      form.setAttribute("data-turbo-frame", "_top")
      document.querySelector("turbo-frame#drawer .qb-drawer-panel").append(form)
      form.dispatchEvent(new CustomEvent("turbo:submit-end", { bubbles: true, detail: {
        success: true,
        formSubmission: { method: "patch", submitter: null },
        fetchResponse: { contentType: "text/html; charset=utf-8" }
      } }))
      // Una navegación _top real después renderiza la página nueva; acá el
      // drawer sigue abierto, que es justo cuando el refresco se metía.
      form.dispatchEvent(new CustomEvent("turbo:frame-render", { bubbles: true }))
      document.querySelector("turbo-frame#drawer").dispatchEvent(new CustomEvent("turbo:frame-render", { bubbles: true }))
    JS
    sleep 0.6

    expect(page.evaluate_script("window.__visits")).to eq([])
  end
end
