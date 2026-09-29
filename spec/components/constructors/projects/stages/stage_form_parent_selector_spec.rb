# frozen_string_literal: true

require "rails_helper"

# El alta de etapa vive en su ruta (stages#new, en el drawer global). El padre
# se elige plegado detrás de "Es sub-etapa de otra etapa" y sólo si hay etapas
# principales; nunca aparece la vieja opción "— Etapa raíz —".
RSpec.describe Constructors::Projects::Stages::StageFormComponent, type: :component do
  let(:project) { create(:project) }

  it "obra sin etapas: no ofrece elegir etapa padre" do
    render_inline(described_class.new(project: project, stage: project.project_stages.build, in_drawer: true))

    expect(page).to have_no_css("select[name='project_stage[parent_id]']", visible: :all)
    expect(page).to have_no_text("Etapa raíz")
  end

  it "con etapas principales: selector plegado" do
    create(:project_stage, project: project, name: "Replanteo")
    render_inline(described_class.new(project: project, stage: project.project_stages.build, in_drawer: true))

    expect(page).to have_css("details summary", text: "Es sub-etapa de otra etapa")
    expect(page).to have_css("details select[name='project_stage[parent_id]'] option", text: "Replanteo", visible: :all)
    expect(page).to have_no_text("Etapa raíz")
  end

  it "desde Agregar sub-etapa: el padre viaja fijo, sin selector" do
    root = create(:project_stage, project: project, name: "Replanteo")
    render_inline(described_class.new(project: project, stage: project.project_stages.build(parent: root), in_drawer: true))

    expect(page).to have_css("input[type=hidden][name='project_stage[parent_id]'][value='#{root.id}']", visible: :all)
    expect(page).to have_no_css("details select[name='project_stage[parent_id]']", visible: :all)
  end
end
