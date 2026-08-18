require 'rails_helper'

# El desktop unifica Resumen + Planificación en la landing del proyecto
# (constructors_project_path); /stages redirige ahí.
RSpec.describe 'QB OS · Stages workspace', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora', status: :in_progress) }
  before do
    create(:project_stage, project: project, name: 'Estructura', position: 1, progress: 60)
    create(:project_stage, project: project, name: 'Mampostería', position: 2, progress: 0)
    sign_in_user(user)
  end

  it 'renders the page header with stage counters' do
    visit constructors_project_path(project)
    expect(page).to have_text('Etapas')
    expect(page).to have_text(/2 etapas principales/)
  end

  it 'renders the two view tabs (Etapas/Gantt) — WBS was removed' do
    visit constructors_project_path(project)
    expect(page).to have_button('Etapas')
    expect(page).to have_button('Gantt')
    expect(page).to have_no_button('WBS')
  end

  # El panel del Gantt arranca con display:none (lo muestra el switcher), así
  # que se inspecciona con visible: :all — rack_test no corre Stimulus.
  it 'renders gantt rows as links into the stage_detail drawer frame, with the budget column' do
    visit constructors_project_path(project)
    stage = project.project_stages.find_by(name: 'Estructura')
    within('[data-qb--view-switcher-target="panel"][data-view="gantt"]', visible: :all) do
      expect(page).to have_text(:all, 'Gastos/Ppto.')
      expect(page).to have_css(
        "a[href='#{constructors_project_stage_path(project, stage)}'][data-turbo-frame='stage_detail']",
        visible: :all, minimum: 1
      )
    end
  end

  it 'lists root stages as cards' do
    visit constructors_project_path(project)
    expect(page).to have_text('Estructura')
    expect(page).to have_text('Mampostería')
  end

  it 'renders the Aplicar plantilla and Nueva etapa modals (hidden by default)' do
    visit constructors_project_path(project)
    expect(page).to have_button('Aplicar plantilla')
    expect(page).to have_button('Nueva etapa')
    # Modal panels exist in the DOM but start hidden — the dialog targets
    # carry the .hidden class until qb--modal#open fires.
    expect(page).to have_css('[data-qb--modal-target="dialog"]', visible: :all)
  end
end
