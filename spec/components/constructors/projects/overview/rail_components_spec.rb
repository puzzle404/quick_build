# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::Overview::UpcomingDeadlinesComponent, type: :component do
  let(:project) { create(:project) }

  it "lista las etapas sin terminar por fecha de fin, vencidas primero y en rojo" do
    late  = create(:project_stage, project: project, name: "Revoques", start_date: Date.current - 20, end_date: Date.current - 3, progress: 10)
    soon  = create(:project_stage, project: project, name: "Pintura", start_date: Date.current - 5, end_date: Date.current + 5, progress: 0)
    later = create(:project_stage, project: project, name: "Entrega", start_date: Date.current, end_date: Date.current + 60, progress: 0)
    create(:project_stage, project: project, name: "Terminada", start_date: Date.current - 60, end_date: Date.current - 30, progress: 100)
    create(:project_stage, project: project, name: "Sin fecha", start_date: nil, end_date: nil, progress: 0)

    render_inline(described_class.new(project: project, stages: [ later, soon, late ]))

    expect(page.all("a").map { |a| a.text.squish }).to match([ /Revoques.*vencida hace 3d/, /Pintura.*en 5d/, /Entrega/ ])
    expect(page).to have_no_text("Terminada")
  end

  it "sin pendientes muestra un vacío" do
    render_inline(described_class.new(project: project, stages: []))

    expect(page).to have_text("Sin etapas pendientes con fecha de fin.")
  end
end

RSpec.describe Constructors::Projects::Overview::HealthStripComponent, type: :component do
  it "muestra avance real con delta vs plan, riesgos y el próximo vencimiento" do
    project = create(:project)
    stage = create(:project_stage, project: project, name: "Revoques", start_date: Date.current, end_date: Date.current + 7, progress: 0)
    decorated = ProjectDecorator.new(project)
    allow(decorated).to receive_messages(progress_percent: 40, planned_progress: 55)

    render_inline(described_class.new(project: decorated, stages: [ stage ]))

    expect(page).to have_text("40%")
    expect(page).to have_text("Δ −15")
    expect(page).to have_text("Próx. vence")
    expect(page).to have_text("Revoques")
  end
end

RSpec.describe Constructors::Projects::Overview::RisksPanelComponent, type: :component do
  it "suma entrega vencida (con acción para reprogramar) y etapas atrasadas" do
    project = create(:project, start_date: Date.current - 90, end_date: Date.current - 5, status: :in_progress)
    late = create(:project_stage, project: project, name: "Revoques", start_date: Date.current - 30, end_date: Date.current - 2, progress: 20)

    component = described_class.new(project: project, stages: [ late ])
    titles = component.items.map { |i| i[:title] }

    expect(titles).to include("Entrega vencida", "1 etapa atrasada")
    render_inline(component)
    expect(page).to have_link("Reprogramar entrega →", href: "/constructors/projects/#{project.id}/edit")
  end
end

RSpec.describe Constructors::Projects::Overview::LogbookComponent, type: :component do
  it "une notas y actividad en una línea de tiempo, más reciente primero" do
    project = create(:project)
    create(:note, noteable: project, author: project.owner, title: "Hormigonado", body: "Losa 3", created_at: 1.hour.ago)
    activity = [ { title: "Proyecto creado", description: "Se creó la obra.", timestamp: 2.days.ago } ]

    with_request_url "/constructors/projects/#{project.id}" do
      vc_test_controller.define_singleton_method(:current_user) { project.owner }
      render_inline(described_class.new(project: project, notes: project.notes.to_a, activity_entries: activity))
    end

    kinds = page.all("#project_notes_list [data-kind]").map { |n| n["data-kind"] }
    expect(kinds).to eq(%w[note activity])
    expect(page).to have_button("Notas")
    expect(page).to have_button("Actividad")
  end
end

RSpec.describe Constructors::Projects::Overview::ProjectFactsComponent, type: :component do
  it "muestra la ficha cargada al crear la obra y ofrece completar lo que falta" do
    owner = create(:user, :constructor)
    project = create(:project, owner: owner, client: "Inmobiliaria Delta", description: nil,
                               start_date: Date.new(2025, 11, 4), end_date: Date.new(2026, 8, 18), budget_cents: 8_450_000_000)

    vc_test_controller.define_singleton_method(:current_user) { owner }
    render_inline(described_class.new(project: project))

    expect(page).to have_text("Inmobiliaria Delta")
    expect(page).to have_text("04 nov 2025")
    expect(page).to have_text("$ 84.500.000")
    expect(page).to have_link("Agregar descripción", href: "/constructors/projects/#{project.id}/edit")
    expect(page).to have_link("Editar datos")
  end
end
