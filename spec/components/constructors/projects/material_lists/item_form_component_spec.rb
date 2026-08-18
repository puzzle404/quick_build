require "rails_helper"

RSpec.describe Constructors::Projects::MaterialLists::ItemFormComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:list) { create(:material_list, project: project) }
  let(:item) { list.material_items.build }

  it "renders new item form" do
    render_inline described_class.new(project: project, material_list: list, material_item: item)
    expect(page).to have_field("Material")
    expect(page).to have_field("Cantidad")
    expect(page).to have_button("Agregar material")
  end
end

