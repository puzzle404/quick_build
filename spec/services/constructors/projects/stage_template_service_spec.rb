# frozen_string_literal: true

require "rails_helper"

# Ida y vuelta completo: capturar la WBS de una obra como plantilla (offsets
# relativos) y aplicarla sobre otra obra que arranca en otra fecha.
RSpec.describe Constructors::Projects::StageTemplateCaptureService do
  let(:owner) { create(:user, :constructor) }
  let(:source) do
    create(:project, owner: owner, start_date: Date.new(2026, 3, 1),
           end_date: Date.new(2026, 9, 1), budget_cents: 10_000_000)
  end

  let!(:root) do
    create(:project_stage, project: source, name: "Estructura",
           start_date: Date.new(2026, 3, 11), end_date: Date.new(2026, 3, 21),
           budget_cents: 2_000_000, progress: 55, spent_cents: 900_000)
  end
  let!(:sub) do
    create(:project_stage, project: source, parent: root, name: "Encofrado",
           start_date: Date.new(2026, 3, 11), end_date: Date.new(2026, 3, 15),
           budget_cents: 500_000, progress: 30)
  end

  def capture
    described_class.call(project: source, owner: owner, name: "Obra tipo", description: "Test")
  end

  it "guarda las fechas como offsets relativos al inicio de la obra" do
    result = capture

    expect(result).to be_success
    expect(result.stages).to eq(1)
    expect(result.sub_stages).to eq(1)

    item = result.template.items.find_by(name: "Estructura")
    expect(item.start_offset_days).to eq(10) # 11-mar menos 1-mar
    expect(item.duration_days).to eq(10)     # 21-mar menos 11-mar
    expect(item.budget_cents).to eq(2_000_000)
    expect(item.budget_pct).to eq(20.0)      # 2M sobre 10M
  end

  it "no copia progreso ni gasto (la plantilla es un plan, no un estado)" do
    item = capture.template.items.find_by(name: "Estructura")

    expect(item.attributes.keys).not_to include("progress", "spent_cents")
  end

  it "rechaza un nombre repetido del mismo dueño sin persistir ítems" do
    capture
    second = described_class.call(project: source, owner: owner, name: "Obra tipo")

    expect(second).not_to be_success
    expect(second.template.errors[:name]).to be_present
    expect(StageTemplate.where(owner: owner).count).to eq(1)
  end

  describe "aplicar la plantilla en otra obra" do
    let(:target) do
      create(:project, owner: owner, start_date: Date.new(2027, 1, 10), budget_cents: 20_000_000)
    end
    let(:template) { capture.template }

    it "recalcula las fechas desde el inicio de la obra destino" do
      Constructors::Projects::StageTemplateService.call(target, template: template)

      stage = target.project_stages.find_by(name: "Estructura")
      expect(stage.start_date).to eq(Date.new(2027, 1, 20)) # 10-ene + 10 días
      expect(stage.end_date).to eq(Date.new(2027, 1, 30))
      expect(stage.sub_stages.pluck(:name)).to eq([ "Encofrado" ])
    end

    it "no copia presupuestos salvo que se pidan explícitamente" do
      Constructors::Projects::StageTemplateService.call(target, template: template)
      expect(target.project_stages.find_by(name: "Estructura").budget_cents).to be_nil

      other = create(:project, owner: owner, start_date: Date.new(2027, 1, 10), budget_cents: 20_000_000)
      Constructors::Projects::StageTemplateService.call(other, template: template, apply_budgets: true)
      # El porcentaje manda cuando la obra destino tiene presupuesto: 20% de 20M.
      expect(other.project_stages.find_by(name: "Estructura").budget_cents).to eq(4_000_000)
    end

    it "es idempotente: no duplica ni pisa lo que ya existe" do
      existing = create(:project_stage, project: target, name: "Estructura",
                        start_date: Date.new(2027, 5, 5), end_date: Date.new(2027, 5, 9),
                        budget_cents: 111)

      expect {
        Constructors::Projects::StageTemplateService.call(target, template: template, apply_budgets: true)
      }.to change { target.project_stages.count }.by(1) # sólo la sub-etapa nueva

      existing.reload
      expect(existing.start_date).to eq(Date.new(2027, 5, 5))
      expect(existing.budget_cents).to eq(111)
    end

    it "crea las etapas sin fechas cuando la obra destino no tiene inicio" do
      undated = create(:project, owner: owner, start_date: nil, end_date: nil)
      Constructors::Projects::StageTemplateService.call(undated, template: template)

      expect(undated.project_stages.find_by(name: "Estructura").start_date).to be_nil
    end
  end

  it "sigue aplicando la plantilla base hardcodeada sin template" do
    target = create(:project, owner: owner, start_date: Date.new(2027, 1, 10))
    result = Constructors::Projects::StageTemplateService.call(target)

    expect(result.created).to eq(3)
    expect(result.sub_created).to eq(11)
    expect(target.project_stages.root.pluck(:name)).to include("Proyecto y gestión")
  end
end
