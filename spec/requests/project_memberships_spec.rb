require 'rails_helper'

RSpec.describe 'ProjectMemberships', type: :request do
  describe 'POST /projects/:project_id/project_memberships' do
    it 'adds a member to the project' do
      constructor = create(:user, :constructor)
      project = create(:project, owner: constructor)
      member = create(:user)

      sign_in constructor
      post project_project_memberships_path(project), params: { project_membership: { user_id: member.id, role: 'worker' } }

      expect(response).to redirect_to(project_path(project))
      project.reload
      expect(project.members).to include(member)
    end
  end

  describe 'DELETE /projects/:project_id/project_memberships/:id' do
    it 'removes a member from the project' do
      constructor = create(:user, :constructor)
      member = create(:user)
      project = create(:project, owner: constructor)
      membership = create(:project_membership, project: project, user: member)

      sign_in constructor
      delete project_project_membership_path(project, membership)

      expect(response).to redirect_to(project_path(project))
      project.reload
      expect(project.members).not_to include(member)
    end
  end
end
