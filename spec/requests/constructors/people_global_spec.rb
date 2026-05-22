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
end
