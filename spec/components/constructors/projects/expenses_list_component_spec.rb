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
    # Per-row amounts: qb_fmt_cents(10_000) = "$ 100", qb_fmt_cents(20_000) = "$ 200"
    expect(page).to have_text("$ 100")
    expect(page).to have_text("$ 200")
    # Total = 10_000 + 20_000 = 30_000 cents → qb_fmt_cents(30_000) = "$ 300"
    expect(page).to have_text("$ 300")
  end

  it "renders category labels in Spanish" do
    expense = create(:expense, project: project, author: owner,
                               category: :materials_misc, incurred_on: Date.today,
                               amount_cents: 50_00)
    render_inline described_class.new(expenses: [ expense ], project: project)
    expect(page).to have_text("Materiales sueltos")
  end

  describe "columna Etapa y comprobante (listado a nivel proyecto)" do
    it "linkea la etapa del gasto y muestra guion cuando no tiene" do
      with_stage = create(:expense, project: project, project_stage: stage, author: owner,
                                    description: "Con etapa", amount_cents: 100_00)
      without    = create(:expense, project: project, project_stage: nil, author: owner,
                                    description: "Sin etapa", amount_cents: 100_00)

      render_inline described_class.new(expenses: [ with_stage, without ], project: project)

      expect(page).to have_css("th", text: "Etapa")
      expect(page).to have_link(stage.name, href: "/constructors/projects/#{project.id}/stages/#{stage.id}")
      expect(page).to have_text("—")
    end

    it "linkea el comprobante adjunto" do
      expense = create(:expense, :with_receipt, project: project, author: owner, amount_cents: 100_00)

      render_inline described_class.new(expenses: [ expense ], project: project)

      expect(page).to have_css("th", text: "Comprobante")
      expect(page).to have_link("Ver", href: /#{expense.receipt.blob.key}|rails\/active_storage/)
    end

    it "no agrega la columna Etapa cuando la lista ya está acotada a una etapa" do
      expense = create(:expense, project: project, project_stage: stage, author: owner, amount_cents: 100_00)
      render_inline described_class.new(expenses: [ expense ], project: project, stage: stage)
      expect(page).not_to have_css("th", text: "Etapa")
    end
  end
end
