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
      @project.expenses.sum(:amount_cents)
    end

    def approved_materials_total
      MaterialItem
        .joins(:material_list)
        .where(material_lists: { project_id: @project.id, status: MaterialList.statuses[:approved] })
        .sum("material_items.quantity * material_items.estimated_cost_cents")
        .to_i
    end
  end
end
