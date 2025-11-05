# frozen_string_literal: true

module Constructors
  module Projects
    class ImagesPanelComponent < ViewComponent::Base
      def initialize(project:, limit: 3)
        @project = project
        @limit = limit
      end

      private

      attr_reader :project, :limit

      def preview_images
        @preview_images ||= project.images.includes(file_attachment: :blob).order(created_at: :desc).limit(limit)
      end

      def total_count
        @total_count ||= project.images.count
      end

      def extra_count
        [total_count - preview_images.size, 0].max
      end

      def index_path
        helpers.constructors_project_images_path(project)
      end
    end
  end
end
