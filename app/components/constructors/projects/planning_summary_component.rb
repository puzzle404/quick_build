# frozen_string_literal: true

module Constructors
  module Projects
    class PlanningSummaryComponent < ViewComponent::Base
      include Constructors::ProjectsHelper

      def initialize(project:)
        @project = project
      end

      private

      attr_reader :project

      def stages_count
        project.project_stages.count
      end

      def material_lists_count
        project.material_lists.count
      end

      def planning_path
        helpers.constructors_project_planning_path(project)
      end

      def duration_value
        return project.duration_text if project.respond_to?(:duration_text)
        nil
      end
    end
  end
end
