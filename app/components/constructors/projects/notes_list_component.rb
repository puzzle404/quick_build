# frozen_string_literal: true

module Constructors
  module Projects
    class NotesListComponent < ViewComponent::Base
      def initialize(notes:, noteable:, project:, bare: false)
        @notes    = notes
        @noteable = noteable
        @project  = project
        @bare     = bare
      end

      private

      attr_reader :notes, :noteable, :project, :bare

      def delete_path(note)
        if noteable.is_a?(ProjectStage)
          helpers.constructors_project_stage_note_path(project, noteable, note)
        else
          helpers.constructors_project_note_path(project, note)
        end
      end
    end
  end
end
