require 'rails_helper'

# El kebab del header (Qb::MenuComponent) esconde acciones que antes eran
# botones sueltos. Lo que hay que probar en un browser de verdad es que al
# moverlas adentro del menú NO se perdieron ni el toggle de Stimulus ni los
# atributos de Turbo (turbo-method / turbo-confirm).
RSpec.describe 'QB OS · Menú de acciones del proyecto', type: :system, js: true do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora') }
  before { sign_in_user(user) }

  # Se entra por Documentos y no por la landing para no depender del workspace
  # de etapas: el header sale del mismo partial en las 5 secciones.
  def open_kebab
    visit constructors_project_documents_path(project)
    expect(page).to have_no_link('Editar proyecto')
    find('.qb-proj-actions button[aria-label="Más acciones"]').click
  end

  it 'abre el menú y abre la edición del proyecto en el drawer' do
    open_kebab
    click_link 'Editar proyecto'

    # "Editar proyecto" abre projects#edit dentro del drawer (Turbo Frame):
    # no navega a una página nueva, así que la URL no cambia.
    expect(page).to have_css('.qb-drawer-title', text: 'Editar obra', wait: 5)
    expect(page).to have_current_path(constructors_project_documents_path(project))
  end

  it 'borra la obra desde el menú (turbo-method + confirm siguen vivos)' do
    open_kebab
    accept_confirm { click_link 'Eliminar obra' }
    expect(page).to have_current_path(constructors_projects_path)
    expect(Project.where(id: project.id)).to be_empty
  end
end
