require 'rails_helper'

RSpec.describe 'Constructors::People::Attendances', type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:person) { create(:project_person, project: project) }

  before { sign_in(owner) }

  it 'creates an attendance' do
    post constructors_project_person_attendances_path(project, person), params: { person_attendance: { latitude: -34.6, longitude: -58.38, source: 'manual' } }
    follow_redirect!
    expect(response.body).to include('Presente registrado').or include('Asistencias')
  end
end

