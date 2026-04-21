require 'rails_helper'

RSpec.describe 'QB OS · Planning', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora', status: :in_progress) }
  before do
    create(:project_stage, project: project, name: 'Estructura', position: 1, progress: 60)
    create(:project_stage, project: project, name: 'Mampostería', position: 2, progress: 0)
    sign_in_user(user)
  end

  it 'renders the page header with stage counters' do
    visit constructors_project_planning_path(project)
    expect(page).to have_text('Planificación · Etapas')
    expect(page).to have_text(/2 etapas principales/)
  end

  it 'renders the three view tabs (Etapas/Gantt/WBS)' do
    visit constructors_project_planning_path(project)
    expect(page).to have_button('Etapas')
    expect(page).to have_button('Gantt')
    expect(page).to have_button('WBS')
  end

  it 'lists root stages as cards' do
    visit constructors_project_planning_path(project)
    expect(page).to have_text('Estructura')
    expect(page).to have_text('Mampostería')
  end

  it 'renders the Aplicar plantilla and Nueva etapa modals (hidden by default)' do
    visit constructors_project_planning_path(project)
    expect(page).to have_button('Aplicar plantilla')
    expect(page).to have_button('Nueva etapa')
    # Modal panels exist in the DOM but start hidden — the dialog targets
    # carry the .hidden class until qb--modal#open fires.
    expect(page).to have_css('[data-qb--modal-target="dialog"]', visible: :all)
  end
end
