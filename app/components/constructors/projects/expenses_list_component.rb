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

      # +show_stage+: agrega la columna Etapa (default: sólo cuando la lista no
      # está ya acotada a una etapa). +return_to+: path al que vuelve el borrado
      # (el listado de Gastos usa el suyo para no patear al usuario a Etapas).
      def initialize(expenses:, project:, stage: nil, bare: false, show_stage: nil, return_to: nil)
        @expenses   = expenses
        @project    = project
        @stage      = stage
        @bare       = bare
        @show_stage = show_stage.nil? ? stage.blank? : show_stage
        @return_to  = return_to
      end

      private

      attr_reader :expenses, :project, :stage, :bare, :show_stage, :return_to

      def category_label(expense)
        CATEGORY_LABELS[expense.category.to_s] || expense.category.to_s.humanize
      end

      # Borrar un gasto es editor de obra en adelante (ExpensePolicy).
      def can_destroy?(expense)
        helpers.policy(expense).destroy?
      end

      # La columna de acciones desaparece entera para quien no puede borrar
      # (si no, queda una columna vacía al final de la tabla).
      def show_actions_column?
        expenses.any? { |expense| can_destroy?(expense) }
      end

      def total_cents
        expenses.sum(&:amount_cents)
      end

      def stage_path(expense)
        helpers.constructors_project_stage_path(project, expense.project_stage)
      end

      # El comprobante se sube desde el modal de gasto; sin este link no había
      # forma de volver a verlo desde ninguna pantalla.
      def receipt_path(expense)
        helpers.rails_blob_path(expense.receipt, disposition: :inline)
      end

      def material_list_path(expense)
        helpers.constructors_project_material_list_path(project, expense.material_list)
      end

      def delete_path(expense)
        base = base_delete_path(expense)
        return base if return_to.blank?

        "#{base}?#{{ return_to: return_to }.to_query}"
      end

      def base_delete_path(expense)
        return helpers.constructors_project_stage_expense_path(project, stage, expense) if stage

        helpers.constructors_project_expense_path(project, expense)
      end

      # Fecha · Categoría · Descripción [· Etapa] · Comprobante · Monto · borrar
      def colspan_before_total
        show_stage ? 4 : 3
      end
    end
  end
end
