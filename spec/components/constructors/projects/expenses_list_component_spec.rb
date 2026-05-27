# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::ExpensesListComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage)   { create(:project_stage, project: project) }

  it "renders the empty state when there are no expenses" do
    render_inline described_class.new(expenses: [], project: project, stage: stage)
    expect(page).to have_text("Todavía no se registraron gastos")
  end

  it "renders expense rows with description and correct total" do
    expense1 = create(:expense, project: project, project_stage: stage, author: owner,
                                amount_cents: 100_00, description: "Jornal albañil",
                                category: :labor, incurred_on: Date.today)
    expense2 = create(:expense, project: project, project_stage: stage, author: owner,
                                amount_cents: 200_00, description: "Alquiler andamio",
                                category: :rentals, incurred_on: Date.today)

    render_inline described_class.new(
      expenses: [ expense1, expense2 ],
      project: project,
      stage: stage
    )

    expect(page).to have_text("Jornal albañil")
    expect(page).to have_text("Alquiler andamio")
    # Total = 100.00 + 200.00 = 300.00
    expect(page).to have_text("300")
  end

  it "renders category labels in Spanish" do
    expense = create(:expense, project: project, author: owner,
                               category: :materials_misc, incurred_on: Date.today,
                               amount_cents: 50_00)
    render_inline described_class.new(expenses: [ expense ], project: project)
    expect(page).to have_text("Materiales sueltos")
  end
end
