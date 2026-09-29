# frozen_string_literal: true

module Exports
  # Versión bulk de Projects::SpendSummary#total_cents.
  #
  # SpendSummary resuelve UNA obra en 3 queries. El dashboard exporta la cartera
  # completa (110 obras en la base de dev), así que usarla en el loop serían
  # ~330 queries por descarga. Esta clase calcula lo mismo para N obras en
  # 3 queries fijas y devuelve hashes {project_id => cents}.
  #
  # Misma definición que SpendSummary, a propósito:
  #   gasto a la fecha = Expenses reales
  #                    + estimado de las listas de materiales aprobadas que
  #                      todavía NO se pagaron (las pagadas ya viajan como
  #                      Expense, contarlas otra vez sería doble conteo).
  #
  # OJO: la definición vive duplicada en dos lugares. Si cambia en
  # Projects::SpendSummary hay que reflejarla acá (ver handoff: lo prolijo sería
  # un `Projects::SpendSummary.bulk_for(project_ids)` y que ambas la lean).
  class SpendTotals
    def initialize(project_ids)
      @project_ids = Array(project_ids).compact.uniq
    end

    def total_cents(project_id)
      expenses_cents(project_id) + materials_cents(project_id)
    end

    def expenses_cents(project_id)
      expenses_by_project[project_id].to_i
    end

    # Estimado comprometido en listas aprobadas y aún no pagadas.
    def materials_cents(project_id)
      materials_by_project[project_id].to_i
    end

    def total_cents_all
      expenses_cents_all + materials_cents_all
    end

    def expenses_cents_all
      @expenses_cents_all ||= expenses_by_project.values.sum(&:to_i)
    end

    def materials_cents_all
      @materials_cents_all ||= materials_by_project.values.sum(&:to_i)
    end

    private

    attr_reader :project_ids

    def expenses_by_project
      @expenses_by_project ||= return_empty_or do
        Expense.where(project_id: project_ids).group(:project_id).sum(:amount_cents)
      end
    end

    def materials_by_project
      @materials_by_project ||= return_empty_or do
        scope = MaterialItem
          .joins(:material_list)
          .where(material_lists: { project_id: project_ids, status: MaterialList.statuses[:approved] })
        scope = scope.where.not(material_lists: { id: paid_material_list_ids }) if paid_material_list_ids.any?

        scope.group("material_lists.project_id")
             .sum("material_items.quantity * material_items.estimated_cost_cents")
             .transform_values { |cents| cents.round.to_i }
      end
    end

    def paid_material_list_ids
      @paid_material_list_ids ||= return_empty_or([]) do
        Expense.where(project_id: project_ids).from_material_lists.distinct.pluck(:material_list_id)
      end
    end

    def return_empty_or(empty = {})
      return empty if project_ids.empty?

      yield
    end
  end
end
