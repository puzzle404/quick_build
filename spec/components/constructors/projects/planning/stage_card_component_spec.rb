# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::Planning::StageCardComponent, type: :component do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before do
    user = owner
    vc_test_controller.define_singleton_method(:current_user) { user }
  end

  # Regresión: las filas de sub-etapas eran links comunes y abrían el detalle
  # como página completa en vez de en el drawer de la derecha.
  it "abre cada sub-etapa en el drawer global, igual que la etapa principal" do
    root = create(:project_stage, project: project, name: "Estructura")
    sub = create(:project_stage, project: project, parent: root, name: "Losas 1°–3°")

    render_inline(described_class.new(project: ProjectDecorator.new(project), stage: root.decorate, sub_stages: [ sub.decorate ]))

    link = page.find("a[href='/constructors/projects/#{project.id}/stages/#{sub.id}']")
    expect(link["data-turbo-frame"]).to eq("drawer")
    expect(link["data-action"]).to include("qb--drawer#open")
    expect(page).to have_css("#card_project_stage_#{root.id}")
  end
end
