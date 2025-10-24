require "rails_helper"

RSpec.describe Constructors::Projects::Stages::StageCardComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:stage) { create(:project_stage, project: project, name: "Estructura") }

  it "renders stage name and period" do
    render_inline described_class.new(project: project, stage: stage)

    expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(stage)}")
    expect(page).to have_text("Estructura")
    expect(page).to have_text(I18n.l(stage.start_date, format: :short))
  end
end

