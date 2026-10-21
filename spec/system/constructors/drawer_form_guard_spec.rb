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
