# frozen_string_literal: true

module Constructors
  module Projects
    class ExpenseFormComponent < ViewComponent::Base
      CATEGORY_OPTIONS = [
        [ "Mano de obra", "labor" ],
        [ "Materiales sueltos", "materials_misc" ],
        [ "Alquileres", "rentals" ],
        [ "Otros", "other" ]
      ].freeze

      def initialize(project:, stage: nil, expense: nil)
        @project = project
        @stage   = stage
        @expense = expense || Expense.new
      end

      private

      attr_reader :project, :stage, :expense

      def form_url
        if stage
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
