# frozen_string_literal: true

require "rails_helper"

# Alta/baja inline de ítems desde el drawer de la lista (ListDetailComponent).
# Regresión: el form inline no tenía scope y el controller respondía 400
# ("se me sale la pantalla de carga de material y no se guardaba").
RSpec.describe "Constructors::Projects::MaterialLists::MaterialItems", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let(:list) { create(:material_list, project: project, author: constructor) }
  let(:drawer_headers) { { "Turbo-Frame" => "drawer", "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  before { sign_in(constructor) }

  it "el drawer de la lista renderiza el form inline con scope material_item" do
    get constructors_project_material_list_path(project, list), headers: { "Turbo-Frame" => "drawer" }

    expect(response.body).to include('name="material_item[name]"')
    expect(response.body).to include('name="material_item[estimated_cost_pesos]"')
    expect(response.body).to include('data-turbo-frame="drawer"')
  end

  it "crea el ítem desde el drawer, parsea el precio en pesos y vuelve al detalle" do
    expect {
      post constructors_project_material_list_material_items_path(project, list),
           params: { material_item: { name: "Cemento", quantity: "10", unit: "bolsa", estimated_cost_pesos: "12.500,50" } },
           headers: drawer_headers
    }.to change(list.material_items, :count).by(1)

    expect(response).to redirect_to(constructors_project_material_list_path(project, list))
    expect(response).to have_http_status(:see_other)
    expect(list.material_items.find_by!(name: "Cemento").estimated_cost_cents).to eq(1_250_050)
  end

  it "borra el ítem desde el drawer y vuelve al detalle" do
    item = create(:material_item, material_list: list)

    expect {
      delete constructors_project_material_list_material_item_path(project, list, item), headers: drawer_headers
    }.to change(list.material_items, :count).by(-1)

    expect(response).to redirect_to(constructors_project_material_list_path(project, list))
  end
end
