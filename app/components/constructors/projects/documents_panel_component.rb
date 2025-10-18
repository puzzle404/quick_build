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
    end
  end
end
