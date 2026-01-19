# frozen_string_literal: true

module Constructors
  module Projects
    class WelcomeWizardComponent < ViewComponent::Base
      def initialize(project:, is_new_project: false)
        @project = project.respond_to?(:object) ? project.object : project
        @is_new_project = is_new_project
      end

      def render?
        @is_new_project && @project.project_stages.empty?
      end

      def project_path
        helpers.constructors_project_path(@project)
      end

      def stages_path
        helpers.constructors_project_stages_path(@project)
      end

      def apply_template_path
        helpers.apply_template_constructors_project_stages_path(@project)
      end

      def blueprints_path
        helpers.constructors_project_blueprints_path(@project)
      end

      def material_lists_path
        helpers.constructors_project_material_lists_path(@project)
      end
    end
  end
end
