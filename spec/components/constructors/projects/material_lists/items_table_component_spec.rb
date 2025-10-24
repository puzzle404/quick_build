require "rails_helper"

RSpec.describe Constructors::Projects::MaterialLists::ItemsTableComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:project) { create(:project) }
  let(:list) { create(:material_list, project: project) }

  it "renders empty state when no items" do
    list.material_items.destroy_all
    render_inline described_class.new(project: project, material_list: list, material_items: list.material_items, editable: false)
    expect(page).to have_text("Todavía no hay materiales cargados")
  end

  it "renders rows when items exist" do
    render_inline described_class.new(project: project, material_list: list, material_items: list.material_items, editable: true)
    expect(page).to have_text(list.material_items.first.name)
    expect(page).to have_button("Quitar")
  end
end

