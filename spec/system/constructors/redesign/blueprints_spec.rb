require 'rails_helper'

RSpec.describe 'QB OS · Blueprints', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora') }
  before { sign_in_user(user) }

  it 'renders the empty state when there are no blueprints' do
    visit constructors_project_blueprints_path(project)
    expect(page).to have_text('Aún no se cargaron planos.')
    expect(page).to have_link('Subir plano')
  end

  it 'renders header + tabs even when empty' do
    visit constructors_project_blueprints_path(project)
    expect(page).to have_text('Planos · IA')
    # Inner tabs should also render
    expect(page).to have_text('Resumen')
    expect(page).to have_text('Planificación')
  end
end
