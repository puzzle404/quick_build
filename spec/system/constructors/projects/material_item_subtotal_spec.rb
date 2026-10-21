# frozen_string_literal: true

require "rails_helper"

# La fila "agregar ítem" calcula el subtotal mientras se tipea (antes recién
# aparecía al guardar). Mismo formato corto que qb_fmt_cents.
RSpec.describe "Subtotal en vivo de un ítem de materiales", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let(:list) { create(:material_list, project: project, author: constructor) }

  it "muestra cantidad × precio antes de guardar" do
    sign_in_user(constructor)
    visit constructors_project_material_lists_path(project, drawer: constructors_project_material_list_path(project, list))

    output = find("[data-qb--line-subtotal-target='output']", wait: 5)
    expect(output).to have_text("—")

    fill_in "material_item[quantity]", with: "10"
    fill_in "material_item[estimated_cost_pesos]", with: "1500"

    expect(output).to have_text("$ 15k")
  end
end
