# frozen_string_literal: true

module Constructors
  module Dashboard
    class RecentDocumentsPanelComponent < ViewComponent::Base
      def initialize(documents: [])
        @documents = documents
      end

      def render?
        false
      end

      private

      attr_reader :documents

      def owner_label_for(record)
        if record.is_a?(ProjectStage)
          "#{record.project.name} · #{record.name}"
        else
          record.name
        end
      end

      def link_path_for(record)
        if record.is_a?(ProjectStage)
          helpers.constructors_project_stage_path(record.project, record)
        else
          helpers.constructors_project_documents_path(record)
        end
      end
    end
  end
end

