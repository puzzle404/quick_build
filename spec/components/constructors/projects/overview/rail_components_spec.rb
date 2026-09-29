# frozen_string_literal: true

require "rails_helper"

# Panel de la obra (projects#show): 3 tarjetas siempre a la vista.
RSpec.describe Constructors::Projects::Overview::ProgressCardComponent, type: :component do
  let(:today) { Date.new(2026, 6, 1) }

  it "usa los mismos números que el KPI del header (real ponderado vs plan lineal)" do
    project = create(:project, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 12, 31))
    decorated = ProjectDecorator.new(project)
    allow(decorated).to receive_messages(progress_percent: 39, planned_progress: 60)

    render_inline(described_class.new(project: decorated, today: today))

    expect(page).to have_css(".qb-progress-real", text: "39%")
    expect(page).to have_css(".qb-progress-plan", text: "60%")
    expect(page).to have_css(".qb-rail-delta--bad", text: "−21 pts vs plan")
    expect(page).to have_css("svg.qb-progress-chart polyline.qb-chart-real")
    expect(page).to have_css(".qb-progress-axis .is-today", text: "Hoy")
  end

  it "adelantada al plan: delta positivo en verde" do
    project = create(:project, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 12, 31))
    decorated = ProjectDecorator.new(project)
    allow(decorated).to receive_messages(progress_percent: 70, planned_progress: 60)

    render_inline(described_class.new(project: decorated, today: today))

    expect(page).to have_css(".qb-rail-delta--ok", text: "+10 pts vs plan")
  end

  it "sin fechas no dibuja el gráfico y pide cargarlas" do
    project = create(:project, start_date: nil, end_date: nil)

    render_inline(described_class.new(project: project, today: today))

    expect(page).to have_no_css("svg.qb-progress-chart")
    expect(page).to have_text("Cargá las fechas de inicio y entrega")
  end
end

RSpec.describe Constructors::Projects::Overview::AttentionCardComponent, type: :component do
  let(:owner) { create(:user, :constructor) }
  let(:today) { Date.current }

  it "ordena por gravedad (entrega vencida → atrasadas → por vencer) y muestra a lo sumo 3" do
    project = create(:project, owner: owner, status: :in_progress, start_date: today - 200, end_date: today - 10)
    late = create(:project_stage, project: project, name: "Mampostería", start_date: today - 60, end_date: today - 5, progress: 40)
    soon = create(:project_stage, project: project, name: "Cielorrasos", start_date: today - 5, end_date: today + 6, progress: 0)
    soon2 = create(:project_stage, project: project, name: "Pintura", start_date: today, end_date: today + 12, progress: 0)

    component = described_class.new(project: project, stages: [ soon2, soon, late ], today: today)
    expect(component.items.map(&:title)).to eq([ "Entrega vencida", "Etapa atrasada", "Cielorrasos vence en 6 días", "Pintura vence en 12 días" ])

    render_inline(component)
    expect(page).to have_css(".qb-attention-row", count: 3)
    expect(page).to have_text("+ 1 más para revisar")
    expect(page).to have_link("Reprogramar", href: "/constructors/projects/#{project.id}/edit")
    expect(page).to have_link("Ver", href: "#card_project_stage_#{late.id}")
    expect(page).to have_css(".qb-rail-badge--bad", text: "4")
  end

  it "sin pendientes: todo en orden" do
    project = create(:project, owner: owner, start_date: today - 10, end_date: today + 100)

    render_inline(described_class.new(project: project, stages: [], today: today))

    expect(page).to have_text("Todo en orden")
    expect(page).to have_no_css(".qb-rail-badge")
  end
end

RSpec.describe Constructors::Projects::Overview::ObraCardComponent, type: :component do
  let(:owner) { create(:user, :constructor) }

  before do
    user = owner
    vc_test_controller.define_singleton_method(:current_user) { user }
  end

  it "muestra dirección, cliente, plazo y presupuesto, con compartir y abrir en Maps" do
    # (cliente va debajo de la dirección; plazo y presupuesto en 2 columnas)
    project = create(:project, owner: owner, name: "Torre Norte", location: "Av. Colón 1234, Mendoza",
                               latitude: -32.89, longitude: -68.84, client: "Inmobiliaria Delta",
                               start_date: Date.new(2025, 11, 4), end_date: Date.new(2026, 8, 18), budget_cents: 8_450_000_000)
    component = described_class.new(project: project)

    render_inline(component)

    expect(page).to have_text("Av. Colón 1234, Mendoza")
    expect(page).to have_text("Inmobiliaria Delta")
    expect(page).to have_text("04 nov → 18 ago")
    expect(page).to have_text("$ 84.5M")
    expect(page).to have_css("[data-controller='qb--mini-map'][data-qb--mini-map-lat-value='-32.89']")
    expect(page).to have_button("Compartir ubicación")
    expect(page).to have_link("Abrir en Google Maps", href: "https://www.google.com/maps/search/?api=1&query=-32.890000%2C-68.840000")
    expect(component.share_text).to eq("Obra: Torre Norte\nDomicilio: Av. Colón 1234, Mendoza\nMapa: https://www.google.com/maps/search/?api=1&query=-32.890000%2C-68.840000")
  end

  it "sin ubicación ni datos: ofrece ubicar y cargar (edición en el drawer)" do
    project = create(:project, owner: owner, location: nil, latitude: nil, longitude: nil, client: nil, budget_cents: nil)

    render_inline(described_class.new(project: project))

    expect(page).to have_link("Ubicar en el mapa", href: "/constructors/projects/#{project.id}/edit")
    expect(page).to have_text("Sin dirección cargada")
    expect(page).to have_link("Cargar cliente")
    expect(page).to have_no_css("[data-controller='qb--mini-map']")
  end
end

RSpec.describe Constructors::Projects::Overview::LogbookComponent, type: :component do
  it "une notas y actividad en una línea de tiempo, más reciente primero" do
    project = create(:project)
    create(:note, noteable: project, author: project.owner, title: "Hormigonado", body: "Losa 3", created_at: 1.hour.ago)
    activity = [ { title: "Proyecto creado", description: "Se creó la obra.", timestamp: 2.days.ago } ]

    vc_test_controller.define_singleton_method(:current_user) { project.owner }
    render_inline(described_class.new(project: project, notes: project.notes.to_a, activity_entries: activity))

    kinds = page.all("#project_notes_list [data-kind]").map { |n| n["data-kind"] }
    expect(kinds).to eq(%w[note activity])
    expect(page).to have_button("Notas")
    expect(page).to have_button("Actividad")
  end
end
