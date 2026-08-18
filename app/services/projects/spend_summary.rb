module Projects
  class SpendSummary
    def initialize(project)
      @project = project
    end

    def total_cents
      expenses_total + approved_materials_total
    end

    def by_category
      @by_category ||= @project.expenses.group(:category).sum(:amount_cents).transform_keys do |k|
        Expense.categories.key(k)&.to_sym || k.to_sym
      end
    end

    def by_stage
      @by_stage ||= @project.expenses
                             .where.not(project_stage_id: nil)
                             .group(:project_stage_id)
                             .sum(:amount_cents)
    end

    private

    def expenses_total
      @expenses_total ||= @project.expenses.sum(:amount_cents)
    end

    # Estimado de las listas aprobadas, EXCLUYENDO las que ya se marcaron como
    # pagadas: esas ya aportan su monto real vía #expenses_total. Sin este
    # filtro, pagar una lista aprobada la contaba dos veces (estimado + gasto).
    def approved_materials_total
      @approved_materials_total ||= MaterialItem
        .joins(:material_list)
        .where(material_lists: { project_id: @project.id, status: MaterialList.statuses[:approved] })
        .where.not(material_lists: { id: paid_material_list_ids })
        .sum("material_items.quantity * material_items.estimated_cost_cents")
        .round
        .to_i
    end

    def paid_material_list_ids
      @paid_material_list_ids ||= @project.expenses.from_material_lists.distinct.pluck(:material_list_id)
    end
  end
end
