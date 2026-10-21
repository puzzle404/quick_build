# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Menú de cuenta del topbar", type: :system, js: true do
  it "tocar el usuario arriba a la derecha muestra Cerrar sesión, y cierra la sesión" do
    user = create(:user, :constructor)
    sign_in_user(user)
    visit constructors_root_path

    within("header") do
      expect(page).to have_no_button("Cerrar sesión")
      find("button[aria-label='Menú de cuenta']").click
      click_button "Cerrar sesión"
    end

    expect(page).to have_current_path(/session|login|\A\/\z/, wait: 5)
    visit constructors_root_path
    expect(page).to have_no_css("button[aria-label='Menú de cuenta']")
  end
end
