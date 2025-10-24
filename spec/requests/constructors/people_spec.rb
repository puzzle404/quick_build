require 'rails_helper'

RSpec.describe 'Constructors::People', type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before { sign_in(owner) }

  it 'lists people' do
    create(:project_person, project: project, full_name: 'Pedro')
    get constructors_project_people_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Recursos humanos')
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
end

