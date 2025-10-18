# frozen_string_literal: true

module Constructors
  module Projects
    class TeamPanelComponent < ViewComponent::Base
      def initialize(project:, membership:, user_options: nil, role_options: nil)
        @project = project
        @membership = membership
        @user_options = user_options
        @role_options = role_options
      end

      private

      attr_reader :project, :membership

      def project_members
        project.members
      end

      def available_users
        @available_users ||= @user_options || User.order(:email).pluck(:email, :id)
      end

      def membership_roles
        @membership_roles ||= (@role_options || ProjectMembership.roles.keys).map do |role|
          [role.to_s.titleize, role]
        end
      end
    end
  end
end
