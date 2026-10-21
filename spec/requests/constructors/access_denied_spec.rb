# frozen_string_literal: true

require "rails_helper"

# Sin permiso, un GET (y un HEAD, que Rails rutea igual que un GET) vuelve a la
# obra; un envío (POST/PATCH…) vuelve a la página anterior con 303. Brakeman
# marcaba que el HEAD caía en la rama de los envíos (request.get? es false).
RSpec.describe "Acceso denegado en el constructor", type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:viewer) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  before do
    create(:project_membership, project: project, user: viewer, role: :viewer)
    sign_in(viewer)
  end

  it "un GET sin permiso redirige a la obra" do
    get edit_constructors_project_path(project)

    expect(response).to redirect_to(constructors_project_path(project))
  end

  it "un HEAD sin permiso se trata igual que un GET" do
    head edit_constructors_project_path(project)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(constructors_project_path(project))
  end
end
