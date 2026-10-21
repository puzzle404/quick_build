# frozen_string_literal: true

require "rails_helper"

# Reporte del usuario (21/10): "si creo una lista luego tengo que cliquear
# afuera del modal y recargar para verla creada en la lista de listas".
# Después de un guardado exitoso que deja el drawer abierto (acá: el detalle
# de la lista recién creada), la página de atrás se refresca sola y el drawer
# sigue abierto.
RSpec.describe "Crear una lista de materiales desde el drawer", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }

  def drawer_open?
    page.evaluate_script("document.querySelector('#qb_drawer_shell').classList.contains('qb-drawer-open')")
  end

  it "la lista nueva aparece en el listado sin recargar, con el drawer abierto en su detalle" do
    sign_in_user(constructor)
    visit constructors_project_material_lists_path(project)
    within("main") { expect(page).to have_no_text("Hierros del entrepiso") }

    click_link "Nueva lista", match: :first
    fill_in "material_list[name]", with: "Hierros del entrepiso", wait: 5
    click_button "Crear lista"

    within("#qb_drawer_shell") { expect(page).to have_css("h2", text: "Hierros del entrepiso", wait: 5) }
    within("main") { expect(page).to have_text("Hierros del entrepiso", wait: 5) }
    expect(drawer_open?).to be(true)
  end
end
