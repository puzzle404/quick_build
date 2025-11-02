# frozen_string_literal: true

module Constructors
  module Projects
    class DocumentsPanelComponent < ViewComponent::Base
      def initialize(project:)
        @project = project
      end

      private

      attr_reader :project

      def project_images
        project.images
      end

      def project_documents
        @project_documents ||= project.documents.includes(file_attachment: :blob).order(created_at: :desc).limit(4)
      end
    end
  end
end
