# frozen_string_literal: true

module Constructors
  module Projects
    class NoteFormComponent < ViewComponent::Base
      def initialize(noteable:, project:)
        @noteable = noteable
        @project  = project
      end

      private

      attr_reader :noteable, :project

      def form_url
        if noteable.is_a?(ProjectStage)
          helpers.constructors_project_stage_notes_path(project, noteable)
        else
          helpers.constructors_project_notes_path(project)
        end
      end
    end
  end
end
