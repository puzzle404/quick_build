# frozen_string_literal: true

module Constructors
  module Projects
    class ExpensesListComponent < ViewComponent::Base
      CATEGORY_LABELS = {
        "labor"          => "Mano de obra",
        "materials_misc" => "Materiales sueltos",
        "rentals"        => "Alquileres",
        "other"          => "Otros"
      }.freeze

      def initialize(expenses:, project:, stage: nil)
        @expenses = expenses
        @project  = project
        @stage    = stage
      end

      private

      attr_reader :expenses, :project, :stage

      def category_label(expense)
        CATEGORY_LABELS[expense.category.to_s] || expense.category.to_s.humanize
      end

      def total_amount
        expenses.sum(&:amount_cents) / 100.0
      end

      def delete_path(expense)
        if stage
          helpers.constructors_project_stage_expense_path(project, stage, expense)
        else
          helpers.constructors_project_expense_path(project, expense)
        end
      end
    end
  end
end
