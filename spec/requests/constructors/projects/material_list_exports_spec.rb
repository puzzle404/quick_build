# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exportar lista de materiales", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let(:list) { create(:material_list, project: project, author: constructor) }

  before { sign_in(constructor) }

  it "descarga el PDF" do
    get constructors_project_material_list_path(project, list, format: :pdf)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("attachment", ".pdf")
    expect(response.body).to start_with("%PDF")
  end

  it "el CSV sigue trayendo los precios estimados" do
    get constructors_project_material_list_path(project, list, format: :csv)

    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include("Precio unit. est. (ARS)")
  end

  it "el detalle ofrece PDF y Excel" do
    get constructors_project_material_list_path(project, list), headers: { "Turbo-Frame" => "drawer" }

    expect(response.body).to include(constructors_project_material_list_path(project, list, format: :pdf))
    expect(response.body).to include(constructors_project_material_list_path(project, list, format: :csv))
  end

  it "en mobile también se puede bajar el PDF" do
    cookies["qb_mobile_client"] = "1"
    get constructors_project_material_list_path(project, list)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(constructors_project_material_list_path(project, list, format: :pdf))
  end
end
