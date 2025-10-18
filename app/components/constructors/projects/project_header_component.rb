# frozen_string_literal: true

module Constructors
  module Projects
    class ProjectHeaderComponent < ViewComponent::Base
      include Constructors::ProjectsHelper

      def initialize(project:)
        @project = project
      end

      private

      attr_reader :project

      def updated_timestamp
        project.updated_at
      end
    end
  end
end
