require 'rails_helper'

RSpec.describe 'ProjectMemberships', type: :request do
  include_context "roles de obra"

  let(:invitee) { create(:user, :constructor) }

  describe 'POST /projects/:project_id/project_memberships' do
    it 'el owner suma a un miembro con su rol' do
      sign_in owner
      post constructors_project_project_memberships_path(project),
           params: { project_membership: { user_id: invitee.id, role: 'editor' } }

      expect(response).to redirect_to(constructors_project_path(project))
      expect(project.reload.members).to include(invitee)
      expect(project.project_memberships.find_by(user: invitee).effective_role).to eq(:editor)
    end

    it 'el admin de obra también puede invitar' do
      sign_in project_admin
      post constructors_project_project_memberships_path(project),
           params: { project_membership: { user_id: invitee.id, role: 'viewer' } }

      expect(project.reload.members).to include(invitee)
    end

    it 'sin rol explícito entra como viewer, el piso de la matriz' do
      sign_in owner
      post constructors_project_project_memberships_path(project),
           params: { project_membership: { user_id: invitee.id } }

      expect(project.project_memberships.find_by(user: invitee).effective_role).to eq(:viewer)
    end

    it 'rechaza un rol inventado sin romperse (el enum tiraría ArgumentError → 500)' do
      sign_in owner

      expect {
        post constructors_project_project_memberships_path(project),
             params: { project_membership: { user_id: invitee.id, role: 'superadmin' } }
      }.not_to change(ProjectMembership, :count)

      expect(response).to redirect_to(constructors_project_path(project))
      expect(flash[:alert]).to include('rol')
    end

    it 'no crea una membresía para el owner (su acceso sale de owner_id)' do
      sign_in owner

      expect {
        post constructors_project_project_memberships_path(project),
             params: { project_membership: { user_id: owner.id, role: 'admin' } }
      }.not_to change(ProjectMembership, :count)

      expect(flash[:alert]).to be_present
    end

    %i[editor viewer].each do |role|
      it "un #{role} no puede invitar" do
        sign_in public_send(role)

        expect {
          post constructors_project_project_memberships_path(project),
               params: { project_membership: { user_id: invitee.id, role: 'admin' } }
        }.not_to change(ProjectMembership, :count)

        expect(response).to have_http_status(:see_other)
      end
    end

    it 'un constructor de afuera recibe 404' do
      sign_in outsider

      expect {
        post constructors_project_project_memberships_path(project),
             params: { project_membership: { user_id: outsider.id, role: 'admin' } }
      }.not_to change(ProjectMembership, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /projects/:project_id/project_memberships/:id' do
    it 'el owner quita a un miembro' do
      membership = create(:project_membership, project: project, user: invitee)

      sign_in owner
      delete constructors_project_project_membership_path(project, membership)

      expect(response).to redirect_to(constructors_project_path(project))
      expect(project.reload.members).not_to include(invitee)
    end

    it 'un editor no puede quitar a nadie' do
      membership = create(:project_membership, project: project, user: invitee)

      sign_in editor

      expect {
        delete constructors_project_project_membership_path(project, membership)
      }.not_to change(ProjectMembership, :count)
    end

    it 'no permite quitar al owner ni con una membresía vieja apuntándolo' do
      # El owner no debería tener membresía; si quedó una fila de data vieja,
      # borrarla no puede leerse como "sacar al dueño de su obra".
      membership = ProjectMembership.create!(project: project, user: owner, role: :admin)

      sign_in owner

      expect {
        delete constructors_project_project_membership_path(project, membership)
      }.not_to change(ProjectMembership, :count)

      expect(flash[:alert]).to include('dueño')
    end
  end
end
