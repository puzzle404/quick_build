require 'rails_helper'

RSpec.describe 'Constructors::People (global)', type: :request do
  let(:owner) { create(:user, :constructor) }

  before { sign_in(owner) }

  it 'lists people across the constructor projects' do
    project_a = create(:project, owner: owner, name: 'Aurora')
    project_b = create(:project, owner: owner, name: 'Pilar')
    create(:project_person, project: project_a, full_name: 'Pedro García', phone: '+54 9 11 0000', status: :active)
    create(:project_person, project: project_b, full_name: 'Pedro García', phone: '+54 9 11 0000', status: :active)
    create(:project_person, project: project_a, full_name: 'Ana Ruiz',     phone: '+54 9 11 0001', status: :active)

    get constructors_people_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Pedro García')
    expect(response.body).to include('Ana Ruiz')
    # Pedro should appear ONCE (deduped across the 2 projects)
    expect(response.body.scan('Pedro García').size).to eq(1)
  end

  it 'filters by ?q' do
    project = create(:project, owner: owner)
    create(:project_person, project: project, full_name: 'Pedro García')
    create(:project_person, project: project, full_name: 'Ana Ruiz')

    get constructors_people_path, params: { q: 'pedro' }
    expect(response.body).to include('Pedro García')
    expect(response.body).not_to include('Ana Ruiz')
  end

  it 'shows the empty state when there are no people' do
    create(:project, owner: owner)
    get constructors_people_path
    expect(response.body).to include('Aún no sumaste personas a ninguna obra.')
  end

  it 'links each row to the global person page, not to a project team' do
    project = create(:project, owner: owner)
    person = create(:project_person, project: project, full_name: 'Pedro García')

    get constructors_people_path

    expect(response.body).to include(constructors_person_path(person))
    expect(response.body).not_to include(constructors_project_people_path(project))
  end

  describe 'GET /constructors/people/:id' do
    it 'consolidates every assignment of the same person across projects' do
      project_a = create(:project, owner: owner, name: 'Aurora')
      project_b = create(:project, owner: owner, name: 'Pilar')
      person = create(:project_person, project: project_a, full_name: 'Pedro García',
                                       phone: '+54 9 11 0000', role_title: 'Capataz')
      create(:project_person, project: project_b, full_name: 'Pedro García', phone: '+54 9 11 0000')

      get constructors_person_path(person)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Pedro García')
      expect(response.body).to include('Aurora').and include('Pilar')
      expect(response.body).to include(edit_constructors_person_path(person))
    end

    # El scope por owner_id hace que una persona de otro constructor no exista
    # para este usuario (RecordNotFound → 404), ni en show ni en update.
    it "does not expose another constructor's person" do
      other = create(:user, :constructor)
      foreign = create(:project_person, project: create(:project, owner: other))

      get constructors_person_path(foreign)
      expect(response).to have_http_status(:not_found)

      patch constructors_person_path(foreign), params: { project_person: { full_name: 'Hackeada' } }
      expect(response).to have_http_status(:not_found)
      expect(foreign.reload.full_name).not_to eq('Hackeada')
    end
  end

  describe 'PATCH /constructors/people/:id' do
    it 'propagates identity changes to all assignments of that person' do
      project_a = create(:project, owner: owner)
      project_b = create(:project, owner: owner)
      person = create(:project_person, project: project_a, full_name: 'Pedro García', phone: '+54 9 11 0000')
      sibling = create(:project_person, project: project_b, full_name: 'Pedro García', phone: '+54 9 11 0000')

      patch constructors_person_path(person),
            params: { project_person: { full_name: 'Pedro Gárcia Sosa', phone: '+54 9 11 0000', document_id: '30111222' } }

      expect(response).to redirect_to(constructors_person_path(person))
      expect(person.reload.full_name).to eq('Pedro Gárcia Sosa')
      expect(sibling.reload.full_name).to eq('Pedro Gárcia Sosa')
      expect(sibling.document_id).to eq('30111222')
    end

    it 're-renders with 422 and keeps data intact when the name is blank' do
      person = create(:project_person, project: create(:project, owner: owner), full_name: 'Pedro García')

      patch constructors_person_path(person), params: { project_person: { full_name: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(person.reload.full_name).to eq('Pedro García')
    end
  end
end
