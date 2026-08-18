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

      # Borrar una nota es editor de obra en adelante (NotePolicy). Se pregunta
      # por nota y no por proyecto porque la policy es la del record.
      def can_destroy?(note)
        helpers.policy(note).destroy?
      end

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
