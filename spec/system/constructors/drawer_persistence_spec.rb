# frozen_string_literal: true

require "rails_helper"

# El drawer global no se cierra por un F5 ni por un refresh ajeno a él (queda
# en ?drawer=… y el shell es data-turbo-permanent); sí se cierra al navegar a
# otra página y cuando lo que refresca es un guardado del propio drawer.
RSpec.describe "Drawer persistente", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }

  def drawer_open?
    page.evaluate_script("document.querySelector('#qb_drawer_shell').classList.contains('qb-drawer-open')")
  end

  before do
    sign_in_user(constructor)
    visit constructors_project_path(project)
    click_link "Registrar gasto", match: :first
    expect(page).to have_field("expense[amount_pesos]", wait: 5)
  end

  it "sobrevive a un F5 y a un refresh ajeno, conservando lo tipeado" do
    expect(page).to have_current_path(/drawer=/, url: true)

    page.driver.browser.refresh
    expect(page).to have_field("expense[amount_pesos]", wait: 5)

    fill_in "expense[description]", with: "a medio escribir"
    page.execute_script("document.body.insertAdjacentHTML('beforeend', '<turbo-stream action=\"refresh\"></turbo-stream>')")
    sleep 1

    expect(drawer_open?).to be(true)
    expect(page).to have_field("expense[description]", with: "a medio escribir")
  end

  it "se cierra y limpia la URL al guardar desde el propio drawer" do
    fill_in "expense[amount_pesos]", with: "1500"
    select "Mano de obra", from: "expense[category]"
    click_button "Guardar gasto"

    expect(page).to have_css(".qb-toast", text: "Gasto registrado correctamente.", wait: 5)
    expect(drawer_open?).to be(false)
    expect(page).to have_no_current_path(/drawer=/, url: true)
  end

  it "se cierra al navegar a otra página" do
    page.execute_script("Turbo.visit('#{constructors_projects_path}')")
    expect(page).to have_current_path(constructors_projects_path, wait: 5)

    expect(drawer_open?).to be(false)
  end
end
