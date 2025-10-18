# frozen_string_literal: true

module SystemAuthHelpers
  def sign_in_user(user, password: "password")
    visit new_session_path
    fill_in "Correo electrónico", with: user.email
    fill_in "Contraseña", with: password
    click_button "Iniciar Sesión"
  end
end
