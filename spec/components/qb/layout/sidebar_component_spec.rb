require 'rails_helper'

RSpec.describe Qb::Layout::SidebarComponent, type: :component do
  let(:user) { create(:user, :constructor) }

  it 'renders all top-level nav items' do
    with_request_url '/constructors' do
      render_inline(described_class.new(current: :dashboard, user: user))
    end
    expect(page).to have_text('Dashboard')
    expect(page).to have_text('Proyectos')
    expect(page).to have_text('Personas')
    expect(page).to have_text('Biblioteca')
  end

  it 'shows the company switcher' do
    with_request_url '/constructors' do
      render_inline(described_class.new(current: :dashboard, user: user, company_name: 'Fernández Const.'))
    end
    expect(page).to have_text('Fernández Const.')
  end

  it 'renders pinned projects when no project context is active' do
    pinned = [ double('p', id: 42, name: 'Torre Aurora · Edificio', health: :ok, progress: 64, project_short_name: 'Torre Aurora') ]
    with_request_url '/constructors' do
      render_inline(described_class.new(current: :dashboard, user: user, pinned_projects: pinned))
    end
    expect(page).to have_text('Fijados')
    expect(page).to have_text('Torre Aurora')
  end

  it 'renders the active project chip, without duplicating the section tabs shown above the content' do
    project = double('Project', id: 42, code: 'PRJ-042', name: 'Torre Aurora', progress: 64,
                                planned_progress: 68, health: :ok, stages_done: 8, stages_count: 14)
    with_request_url '/constructors/projects/42' do
      render_inline(described_class.new(current: :projects, user: user,
                                         project: project, project_sub: :stages))
    end
    expect(page).to have_text('PRJ-042')
    expect(page).to have_text('Torre Aurora')
    expect(page).to have_text('64% avance')
    # La sección "En este proyecto" (Etapas/Materiales/Gastos/Planos/Equipo/
    # Documentos) se sacó de la sidebar: duplicaba 1:1 los tabs de
    # _section_tabs.html.erb, que además muestran contadores.
    expect(page).to have_no_text('En este proyecto')
  end
end
