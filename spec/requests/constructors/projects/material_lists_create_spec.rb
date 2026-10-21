# frozen_string_literal: true

require "rails_helper"

# El alta de listas responde con un redirect que el frame del drawer sigue
# (con o sin etapa): así qb--drawer refresca la página de atrás y la lista
# nueva aparece sin recargar (reporte del usuario, 21/10).
RSpec.describe "Alta de listas de materiales", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let(:frame) { { "Turbo-Frame" => "drawer", "Accept" => "text/vnd.turbo-stream.html, text/html" } }

  before { sign_in(constructor) }

  it "sin etapa, sigue al detalle de la lista dentro del drawer" do
    post constructors_project_material_lists_path(project), params: { material_list: { name: "Hierros" } }, headers: frame

    list = project.material_lists.find_by!(name: "Hierros")
    expect(response).to redirect_to(constructors_project_material_list_path(project, list))
  end

  it "con etapa, sigue al detalle de la etapa en el tab Materiales (redirect, no stream)" do
    stage = create(:project_stage, project: project, name: "Replanteo")
    post constructors_project_material_lists_path(project),
         params: { material_list: { name: "Estacas", project_stage_id: stage.id } }, headers: frame

    expect(response).to redirect_to(constructors_project_stage_path(project, stage, tab: "materiales"))
  end
end
