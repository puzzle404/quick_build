# frozen_string_literal: true

module Constructors
  module Projects
    class PlanningPanelComponent < ViewComponent::Base
      include Constructors::ProjectsHelper

      def initialize(project:, project_stages:, new_stage:)
        @project = project
        @project_stages = project_stages
        @new_stage = new_stage
      end

      private

      attr_reader :project, :project_stages, :new_stage

      def project_record
        project.respond_to?(:object) ? project.object : project
      end
    end
  end
end
