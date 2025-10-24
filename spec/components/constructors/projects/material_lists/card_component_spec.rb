require "rails_helper"

RSpec.describe Constructors::Projects::MaterialLists::CardComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:list) { create(:material_list, project: project) }

  it "renders list basic info" do
    render_inline described_class.new(project: project, material_list: list)
    expect(page).to have_text(list.name)
    expect(page).to have_text("Uso interno").or have_text("Permitido presupuestar")
  end
end

