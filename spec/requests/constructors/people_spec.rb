require 'rails_helper'

RSpec.describe 'Constructors::People', type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before { sign_in(owner) }

  it 'lists people' do
    create(:project_person, project: project, full_name: 'Pedro')
    get constructors_project_people_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Personas asignadas')
    expect(response.body).to include('Pedro')
  end

  it 'creates a person' do
    post constructors_project_people_path(project), params: { project_person: { full_name: 'Ana', role_title: 'Pintora' } }
    follow_redirect!
    expect(response.body).to include('Persona agregada a la obra').or include('Ana')
  end

  it 'updates a person' do
    person = create(:project_person, project: project, full_name: 'Old')
    patch constructors_project_person_path(project, person), params: { project_person: { full_name: 'New' } }
    follow_redirect!
    expect(response.body).to include('Datos actualizados').or include('New')
  end

  it 'destroys a person' do
    person = create(:project_person, project: project)
    delete constructors_project_person_path(project, person)
    follow_redirect!
    expect(response.body).to include('Persona eliminada').or include('Recursos humanos')
  end

  # Regression guard (final review, fix 2): PersonFormComponent renderiza el
  # mismo form en las dos ramas de new/edit. Con `click->qb--drawer#back`
  # incondicional, en la rama de página completa Cancelar apuntaba al drawer
  # global del layout — que ya está cerrado — y no hacía nada.
  describe 'botón Cancelar del form de persona' do
    it 'en la página completa de #new es un link al listado del equipo' do
      get new_constructors_project_person_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('qb-drawer-panel')
      expect(response.body).to include(%(href="#{constructors_project_people_path(project)}"))
      # Substring exacto con la comilla de cierre: "qb--drawer#back" solo
      # apunta al botón de Cancelar/‹ volver — "qb--drawer#backdrop" (el click
      # fuera del panel, siempre presente en el shell global) también contiene
      # "qb--drawer#back" como substring y daría un falso positivo sin la ".
      expect(response.body).not_to include('qb--drawer#back"')
    end

    it 'en la página completa de #edit es un link a la ficha' do
      person = create(:project_person, project: project, full_name: 'Ana')

      get edit_constructors_project_person_path(project, person)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('qb-drawer-panel')
      expect(response.body).to include(%(href="#{constructors_project_person_path(project, person)}"))
      # Substring exacto con la comilla de cierre: "qb--drawer#back" solo
      # apunta al botón de Cancelar/‹ volver — "qb--drawer#backdrop" (el click
      # fuera del panel, siempre presente en el shell global) también contiene
      # "qb--drawer#back" como substring y daría un falso positivo sin la ".
      expect(response.body).not_to include('qb--drawer#back"')
    end

    it 'dentro del drawer vuelve a la vista anterior en vez de navegar' do
      get new_constructors_project_person_path(project), headers: { 'Turbo-Frame' => 'drawer' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('qb-drawer-panel')
      expect(response.body).to include('qb--drawer#back')
    end
  end
end
