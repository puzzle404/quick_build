# frozen_string_literal: true

module Constructors
  module Projects
    class DocumentsPanelComponent < ViewComponent::Base
      def initialize(project:, limit: 4)
        @project = project
        @limit = limit
      end

      private

      attr_reader :project, :limit

      def preview_documents
        @preview_documents ||= project.documents
                                      .includes(file_attachment: :blob)
                                      .order(created_at: :desc)
                                      .limit(limit)
      end

      def total_count
        @total_count ||= project.documents.count
      end

      def extra_count
        [total_count - preview_documents.size, 0].max
      end

      def index_path
        helpers.constructors_project_documents_path(project)
      end
    end
  end
end
