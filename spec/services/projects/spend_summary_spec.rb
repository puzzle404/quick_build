require 'rails_helper'

RSpec.describe Projects::SpendSummary do
  let(:project) { create(:project) }
  let(:stage)   { create(:project_stage, project: project) }

  subject(:summary) { described_class.new(project) }

  it "es 0 cuando no hay nada cargado" do
    expect(summary.total_cents).to eq(0)
  end

  it "suma expenses por proyecto" do
    create(:expense, project: project, project_stage: nil, amount_cents: 100_00)
    create(:expense, project: project, project_stage: stage, amount_cents: 250_00)
    expect(summary.total_cents).to eq(350_00)
  end

  it "suma material lists aprobadas (sum qty * estimated_cost_cents)" do
    list = create(:material_list, project: project, status: :approved, add_default_item: false)
    create(:material_item, material_list: list, quantity: 4, estimated_cost_cents: 50_00)
    create(:material_item, material_list: list, quantity: 2, estimated_cost_cents: 100_00)
    expect(summary.total_cents).to eq(4 * 50_00 + 2 * 100_00)
  end

  it "ignora material lists no aprobadas" do
    list = create(:material_list, project: project, status: :draft, add_default_item: false)
    create(:material_item, material_list: list, quantity: 4, estimated_cost_cents: 50_00)
    expect(summary.total_cents).to eq(0)
  end

  it "agrupa expenses por categoría" do
    create(:expense, project: project, category: :labor,          amount_cents: 100_00)
    create(:expense, project: project, category: :materials_misc, amount_cents:  50_00)
    expect(summary.by_category[:labor]).to eq(100_00)
    expect(summary.by_category[:materials_misc]).to eq(50_00)
  end

  it "agrupa total por stage_id (expenses)" do
    create(:expense, project: project, project_stage: stage, amount_cents: 300_00)
    expect(summary.by_stage[stage.id]).to eq(300_00)
  end

  it "ignora items con estimated_cost_cents nulo sin romper" do
    list = create(:material_list, project: project, status: :approved, add_default_item: false)
    create(:material_item, material_list: list, quantity: 3, estimated_cost_cents: nil)
    create(:material_item, material_list: list, quantity: 2, estimated_cost_cents: 100_00)
    expect(summary.total_cents).to eq(2 * 100_00)
  end
end
