# frozen_string_literal: true

# Centered modal for inviting an existing user as a project member with a
# role. Submits POST to project_memberships#create. Uses qb--modal Stimulus.
class Constructors::Projects::Overview::InviteMemberModalComponent < ViewComponent::Base
  ROLES = [
    ['Visor',  'viewer'],
    ['Editor', 'editor'],
    ['Admin',  'admin']
  ].freeze

  def initialize(project:)
    @project = project
  end

  attr_reader :project

  # Users that aren't yet members of this project — invite candidates.
  def candidate_user_options
    member_ids = project.project_memberships.pluck(:user_id)
    User.where.not(id: member_ids + [project.owner_id]).order(:email).map { |u| [u.email, u.id] }
  end
end
