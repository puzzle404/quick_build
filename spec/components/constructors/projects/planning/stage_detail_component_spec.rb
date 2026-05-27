# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::Planning::StageDetailComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage) do
    create(:project_stage, project: project,
                           name: "Fundaciones",
                           description: "Excavación y vertido de hormigón",
                           start_date: Date.new(2026, 1, 1),
                           end_date: Date.new(2026, 2, 28),
                           progress: 0)
  end

  subject(:rendered) do
    render_inline described_class.new(project: project, stage: stage)
  end

  # ─── ① IDENTIDAD ────────────────────────────────────────────

  it "renders the WBS code pill" do
    rendered
    expect(page).to have_css(".sd-code-pill")
  end

  it "renders the stage name in the hero h1" do
    rendered
    expect(page).to have_css(".sd-hero-title h1", text: "Fundaciones")
  end

  it "renders the description when present" do
    rendered
    expect(page).to have_css(".sd-hero-desc", text: "Excavación y vertido de hormigón")
  end

  it "shows a status pill with the stage status label" do
    rendered
    # Qb::PillComponent renders a <span> with inline styles
    expect(page).to have_text(/Pendiente|En curso|Completada/)
  end

  it "shows predecessor info when one is set" do
    predecessor = create(:project_stage, project: project, name: "Pilotes",
                                          start_date: Date.new(2025, 12, 1),
                                          end_date: Date.new(2025, 12, 31))
    stage_with_pred = create(:project_stage, project: project,
                                              name: "Zapatas",
                                              predecessor_id: predecessor.id,
                                              start_date: Date.new(2026, 1, 1),
                                              end_date: Date.new(2026, 1, 31))
    render_inline described_class.new(project: project, stage: stage_with_pred)
    expect(page).to have_css(".sd-hero-predecessor", text: /Después de.*Pilotes/)
  end

  # ─── ② MÉTRICAS ─────────────────────────────────────────────

  it "renders the big progress number with percent sign" do
    render_inline described_class.new(project: project, stage: stage)
    expect(page).to have_css(".sd-progress-num", text: "0%")
  end

  it "renders the 3-column metrics row with dates" do
    rendered
    expect(page).to have_css(".sd-metrics .sd-metric .lbl", text: /Inicio/)
    expect(page).to have_css(".sd-metrics .sd-metric .lbl", text: /Fin/)
    expect(page).to have_css(".sd-metrics .sd-metric .lbl", text: /Responsable/)
  end

  # ─── ③ ESTRUCTURA (sub-stages) ──────────────────────────────

  it "hides the sub-stages group when there are no sub-stages" do
    rendered
    expect(page).not_to have_css(".sd-group")
  end

  it "renders sub-stage rows with hierarchical codes" do
    sub1 = create(:project_stage, project: project, name: "Sub A",
                                  parent_id: stage.id, progress: 50,
                                  start_date: Date.new(2026, 1, 1),
                                  end_date: Date.new(2026, 1, 31))
    sub2 = create(:project_stage, project: project, name: "Sub B",
                                  parent_id: stage.id, progress: 0,
                                  start_date: Date.new(2026, 2, 1),
                                  end_date: Date.new(2026, 2, 28))
    render_inline described_class.new(project: project, stage: stage,
                                       sub_stages: [ sub1, sub2 ])
    expect(page).to have_css(".sd-group")
    expect(page).to have_css(".sd-sub-row", count: 2)
    expect(page).to have_css(".sd-sub-name", text: "Sub A")
    expect(page).to have_css(".sd-sub-name", text: "Sub B")
    # Sub-stage codes should look like "N.M"
    expect(page).to have_css(".sd-sub-code", text: /\d+\.\d+/)
  end

  it "computes weighted progress from sub-stages" do
    sub1 = create(:project_stage, project: project, name: "Sub A",
                                  parent_id: stage.id, progress: 100,
                                  start_date: Date.new(2026, 1, 1),
                                  end_date: Date.new(2026, 1, 11))  # 10 days
    sub2 = create(:project_stage, project: project, name: "Sub B",
                                  parent_id: stage.id, progress: 0,
                                  start_date: Date.new(2026, 1, 11),
                                  end_date: Date.new(2026, 1, 21)) # 10 days
    component = described_class.new(project: project, stage: stage, sub_stages: [ sub1, sub2 ])
    # Both 10 days: (100*10 + 0*10) / 20 = 50%
    expect(component.send(:progress_number)).to eq(50)
  end

  # ─── ④ TRABALHO — 5 tabs ────────────────────────────────────

  it "renders the 5 tabs in the tabbed panel" do
    rendered
    %w[Materiales Gastos Notas Docs Fotos].each do |label|
      expect(page).to have_css(".tab", text: label)
    end
  end

  it "renders the Materiales empty state when no lists are linked" do
    rendered
    expect(page).to have_css(".sd-empty-inline-text", text: /0 listas de materiales/)
  end

  # ─── Footer ─────────────────────────────────────────────────

  it "renders footer actions: Eliminar, Duplicar, Editar, Marcar completada" do
    rendered
    expect(page).to have_css(".sd-footer", text: /Eliminar/)
    expect(page).to have_css(".sd-footer .right", text: /Duplicar/)
    expect(page).to have_css(".sd-footer .right", text: /Editar/)
    expect(page).to have_css(".sd-footer .right", text: /Marcar completada/)
  end
end
