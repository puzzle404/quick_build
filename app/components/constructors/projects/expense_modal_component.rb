# frozen_string_literal: true

module Constructors
  module Projects
    # Centered modal to register an expense. When +stage+ is provided the expense
    # is scoped to that stage; otherwise it falls back to the project scope.
    # Uses the qb--modal Stimulus controller (same API as InviteMemberModal).
    class ExpenseModalComponent < ViewComponent::Base
      # Canonical expense category list (label, value) for the select input.
      CATEGORY_OPTIONS = [
        [ "Mano de obra", "labor" ],
        [ "Materiales sueltos", "materials_misc" ],
        [ "Alquileres", "rentals" ],
        [ "Otros", "other" ]
      ].freeze

      def initialize(project:, expense: nil, stage: nil)
        @project = project
        @expense = expense || Expense.new
        @stage   = stage
      end

      private

      attr_reader :project, :expense, :stage

      def stage_scoped?
        stage.present?
      end

      def form_url
        if stage_scoped?
          helpers.constructors_project_stage_expenses_path(project, stage)
        else
          helpers.constructors_project_expenses_path(project)
        end
      end

      def category_options
        CATEGORY_OPTIONS
      end
    end
  end
end
