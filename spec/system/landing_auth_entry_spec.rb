require 'rails_helper'

# La landing pública debe ofrecer siempre una puerta de entrada a la sesión.
# Regresión histórica: `app/assets/tailwind/application.css` declaraba
# `.hidden { display: none !important }` sin scope, así que el contenedor
# `hidden lg:flex` del navbar quedaba oculto en TODOS los anchos y no había
# forma de llegar a "Iniciar sesión" desde el home.
RSpec.describe 'Landing · entrada a la sesión', type: :system do
  it 'muestra Iniciar sesión y Registrarse en desktop' do
    visit root_path

    expect(page).to have_link('Iniciar sesión', href: new_session_path, visible: :visible)
    expect(page).to have_link('Registrarse', href: new_registration_path, visible: :visible)
  end

  it 'muestra Iniciar sesión y Registrarse en mobile sin abrir el menú', js: true do
    page.driver.resize(390, 844)
    visit root_path

    within('header nav') do
      expect(page).to have_link('Iniciar sesión', href: new_session_path, visible: :visible)
      expect(page).to have_link('Registrarse', href: new_registration_path, visible: :visible)
    end
  end

  it 'expone el menú mobile con Iniciar sesión detrás del botón hamburguesa', js: true do
    page.driver.resize(390, 844)
    visit root_path

    # El panel arranca oculto y el hamburguesa lo abre (Stimulus marketing-menu).
    expect(page).to have_css('#mobile-menu.hidden', visible: :all)
    find('#mobile-menu-button').click

    expect(page).to have_no_css('#mobile-menu.hidden', visible: :all)
    within('#mobile-menu') { expect(page).to have_link('Iniciar sesión', href: new_session_path) }
  end

  it 'abre el modal de login dentro de la landing sin perder la página', js: true do
    visit root_path
    click_link 'Iniciar sesión', match: :first

    within('turbo-frame#login_modal') { expect(page).to have_field('Email') }
    expect(page).to have_link('¿Olvidaste tu contraseña?', href: new_password_path)
    expect(page).to have_current_path(root_path)
  end

  it 'permite loguearse desde el modal de la landing', js: true do
    create(:user, :constructor, email: 'jefa@obra.test', password: 'secreto123')

    visit root_path
    click_link 'Iniciar sesión', match: :first

    # La landing tiene su propio form de contacto con campo Email: acotamos al modal.
    within('turbo-frame#login_modal') do
      fill_in 'Email', with: 'jefa@obra.test'
      fill_in 'Contraseña', with: 'secreto123'
      click_button 'Iniciar Sesión'
    end

    expect(page).to have_current_path(constructors_root_path, wait: 5)
  end

  # Regresión: al cerrar sesión desde el constructor, Turbo navegaba a la
  # landing reemplazando sólo el <body>; el <html> seguía con data-theme y
  # `[data-theme] .hidden` escondía el navbar hasta refrescar a mano.
  it 'al cerrar sesión desde la app, la landing muestra Iniciar sesión y Registrarse', js: true do
    user = create(:user, :constructor, email: 'sale@obra.test', password: 'secreto123')
    sign_in_user(user, password: 'secreto123')
    visit constructors_root_path
    expect(page).to have_css('html[data-theme]', visible: :all)

    page.execute_script("document.querySelector('form[action=\"/session\"]').requestSubmit()")

    expect(page).to have_current_path(root_path, wait: 5)
    expect(page).to have_no_css('html[data-theme]', visible: :all, wait: 5)
    within('header nav') do
      expect(page).to have_link('Iniciar sesión', href: new_session_path, visible: :visible)
      expect(page).to have_link('Registrarse', href: new_registration_path, visible: :visible)
    end
  end
end
