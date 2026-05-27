# frozen_string_literal: true

module Constructors
  module Projects
    # Centered modal to register a project-level expense that is NOT tied to a
    # stage. Posts to the project-scoped expenses path; project_stage stays nil.
    # Uses the qb--modal Stimulus controller (same API as InviteMemberModal).
    class ExpenseModalComponent < ViewComponent::Base
      # Reuse the canonical category list from the stage-scoped form.
      CATEGORY_OPTIONS = ExpenseFormComponent::CATEGORY_OPTIONS

      def initialize(project:, expense: nil)
        @project = project
        @expense = expense || Expense.new
      end

      private

      attr_reader :project, :expense

      def form_url
        helpers.constructors_project_expenses_path(project)
      end

      def category_options
        CATEGORY_OPTIONS
      end
    end
  end
end
