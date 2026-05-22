require 'rails_helper'

RSpec.describe 'QB OS · Layout', type: :system do
  let(:user) { create(:user, :constructor) }
  before { sign_in_user(user) }

  it 'renders sidebar + topbar with the constructor brand' do
    visit constructors_root_path
    expect(page).to have_css('aside.qb-sidebar')
    expect(page).to have_text('Quick Build')
    expect(page).to have_text('OPS CONSOLE')
    expect(page).to have_link('Dashboard', href: constructors_root_path)
    expect(page).to have_link('Proyectos', href: constructors_projects_path)
  end

  it 'lists pinned projects in the sidebar when no project is open' do
    create(:project, owner: user, name: 'Torre Aurora · Edificio')
    visit constructors_root_path
    expect(page).to have_text('Fijados')
    expect(page).to have_text('Torre Aurora')
  end

  it 'shows the topbar Inicio crumb by default' do
    visit constructors_root_path
    expect(page).to have_css('header', text: 'Inicio')
  end
end
