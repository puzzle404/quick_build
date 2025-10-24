require "rails_helper"

RSpec.describe Constructors::Projects::ProjectMetricsComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project).decorate }

  it "renders responsive auto-fit grid" do
    render_inline described_class.new(project: project)
    expect(page).to have_css('section.grid[class*="grid-cols-[repeat(auto-fit,minmax(16rem,1fr))]"]')
  end
end

