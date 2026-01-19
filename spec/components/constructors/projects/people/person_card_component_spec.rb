require "rails_helper"

RSpec.describe Constructors::Projects::People::PersonCardComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:person) { create(:project_person, project: project, full_name: "María Lopez") }

  it "renders person name and status badge" do
    render_inline described_class.new(project: project, person: person)
    expect(page).to have_text("María Lopez")
    expect(page).to have_text("Activo")
  end
end

