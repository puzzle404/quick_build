# frozen_string_literal: true

module Constructors
  module Projects
    class ProjectCardComponent < ViewComponent::Base
      include Constructors::ProjectsHelper

      def initialize(project:)
        @project = project
      end

      private

      attr_reader :project

      def show_path
        helpers.constructors_project_path(project)
      end

      def cover_image
        project.images.first&.file
      end

      def stages_count
        project.project_stages.count
      end

      def material_lists_count
        project.material_lists.count
      end

      def location_label
        project.location.presence || 'Ubicación no indicada'
      end

      def status_badge_text
        project.status.to_s.humanize
      end

      def status_badge_tone
        case project.status.to_s
        when 'planned' then :info
        when 'in_progress' then :primary
        when 'completed' then :success
        else :neutral
        end
      end
    end
  end
end
