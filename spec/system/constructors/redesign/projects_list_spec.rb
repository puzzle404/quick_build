require 'rails_helper'

RSpec.describe 'QB OS · Projects list', type: :system do
  let(:user) { create(:user, :constructor) }
  before do
    create(:project, owner: user, status: :in_progress, name: 'Aurora')
    create(:project, owner: user, status: :planned,     name: 'Pilar')
    create(:project, owner: user, status: :completed,   name: 'Retiro')
    sign_in_user(user)
  end

  it 'renders the four status tabs with counts' do
    visit constructors_projects_path
    within('main') do
      expect(page).to have_text('Todos')
      expect(page).to have_text('En obra')
      expect(page).to have_text('Planificados')
      expect(page).to have_text('Finalizados')
    end
  end

  it 'filters by status when ?status=in_progress is set' do
    visit constructors_projects_path(status: 'in_progress')
    within('main') do
      expect(page).to have_text('Aurora')
      expect(page).not_to have_text('Retiro')
      expect(page).not_to have_text('Pilar')
    end
  end

  it 'shows the search input and view toggle' do
    visit constructors_projects_path
    expect(page).to have_field('q')
    expect(page).to have_css('button[data-qb--view-switcher-target="btn"]', count: 2)
  end
end
