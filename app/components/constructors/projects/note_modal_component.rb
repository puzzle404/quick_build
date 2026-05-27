# frozen_string_literal: true

module Constructors
  module Projects
    # Centered modal to add a note. When +stage+ is provided the note is
    # scoped to that stage; otherwise it falls back to the project scope.
    # Uses the qb--modal Stimulus controller (same API as ExpenseModalComponent).
    class NoteModalComponent < ViewComponent::Base
      def initialize(project:, stage: nil)
        @project = project
        @stage   = stage
      end

      private

      attr_reader :project, :stage

      def stage_scoped?
        stage.present?
      end

      def form_url
        if stage_scoped?
          helpers.constructors_project_stage_notes_path(project, stage)
        else
          helpers.constructors_project_notes_path(project)
        end
      end
    end
  end
end
