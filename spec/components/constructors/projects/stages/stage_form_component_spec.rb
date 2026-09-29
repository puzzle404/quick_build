require "rails_helper"

RSpec.describe Constructors::Projects::Stages::StageFormComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:stage) { build(:project_stage, project: project) }

  it "renders form fields" do
    render_inline described_class.new(project: project, stage: stage)
    expect(page).to have_field("Nombre de la etapa")
    expect(page).to have_field("Fecha de inicio")
    expect(page).to have_button("Guardar etapa")
  end
end

