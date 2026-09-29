require "rails_helper"

# Matriz de permisos por obra, ejercida sobre las rutas reales.
#
# Las tres respuestas posibles y por qué son distintas:
#   200/302 → podés
#   403     → estás en la obra pero tu rol no alcanza (viewer que quiere cargar)
#   404     → no estás en la obra: `find_project!` no la encuentra y no
#             confirmamos que exista una obra de otro constructor
RSpec.describe "Acceso por rol de obra", type: :request do
  include_context "roles de obra"

  # Sólo el owner de la obra es dueño de este spec; el resto entra por
  # membresía. `project` y los usuarios vienen del contexto compartido.
  let!(:stage) { create(:project_stage, project: project) }

  # Las lecturas se prueban con GET directo; las escrituras se comparan contra
  # el efecto real (¿se creó la fila?), no sólo contra el status.
  def sign_in_as(user)
    sign_in(user)
  end

  describe "lectura de la obra" do
    %i[owner project_admin editor viewer].each do |role|
      it "#{role} abre la obra y sus secciones" do
        sign_in_as(public_send(role))

        get constructors_project_path(project)
        expect(response).to have_http_status(:ok), "show para #{role}"

        get constructors_project_expenses_path(project)
        expect(response).to have_http_status(:ok), "gastos para #{role}"

        get constructors_project_people_path(project)
        expect(response).to have_http_status(:ok), "equipo para #{role}"

        get constructors_project_material_lists_path(project)
        expect(response).to have_http_status(:ok), "materiales para #{role}"

        get constructors_project_blueprints_path(project)
        expect(response).to have_http_status(:ok), "planos para #{role}"

        get constructors_project_documents_path(project)
        expect(response).to have_http_status(:ok), "documentos para #{role}"
      end
    end

    it "un constructor de afuera recibe 404 (ni siquiera confirma que la obra existe)" do
      sign_in_as(outsider)

      get constructors_project_path(project)
      expect(response).to have_http_status(:not_found)

      get constructors_project_expenses_path(project)
      expect(response).to have_http_status(:not_found)

      get constructors_project_people_path(project)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "cargar un gasto (editor+)" do
    let(:params) { { expense: { amount_pesos: "1500", category: "labor", incurred_on: Date.current, description: "Jornal" } } }

    %i[owner project_admin editor].each do |role|
      it "#{role} puede" do
        sign_in_as(public_send(role))

        expect {
          post constructors_project_expenses_path(project), params: params
        }.to change(Expense, :count).by(1)
      end
    end

    it "viewer no puede" do
      sign_in_as(viewer)

      expect {
        post constructors_project_expenses_path(project), params: params
      }.not_to change(Expense, :count)

      expect(response).to have_http_status(:see_other)
      expect(flash[:alert]).to be_present
    end

    it "viewer tampoco llega al formulario" do
      sign_in_as(viewer)

      get new_constructors_project_expense_path(project)

      expect(response).to redirect_to(constructors_project_path(project))
    end

    it "de afuera da 404" do
      sign_in_as(outsider)

      expect {
        post constructors_project_expenses_path(project), params: params
      }.not_to change(Expense, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "crear una etapa (editor+)" do
    let(:params) { { project_stage: { name: "Cimientos" } } }

    it "editor puede" do
      sign_in_as(editor)

      expect {
        post constructors_project_stages_path(project), params: params
      }.to change(ProjectStage, :count).by(1)
    end

    it "viewer no puede" do
      sign_in_as(viewer)

      expect {
        post constructors_project_stages_path(project), params: params
      }.not_to change(ProjectStage, :count)

      expect(response).to have_http_status(:see_other)
    end
  end

  describe "subir un documento (editor+, no admin)" do
    let(:params) do
      { document: { files: [ Rack::Test::UploadedFile.new(StringIO.new("hola"), "text/plain", original_filename: "nota.txt") ] } }
    end

    it "editor puede (es contenido de obra, no edición de la obra)" do
      sign_in_as(editor)

      expect {
        post constructors_project_documents_path(project), params: params
      }.to change(Document, :count).by(1)
    end

    it "viewer no puede" do
      sign_in_as(viewer)

      expect {
        post constructors_project_documents_path(project), params: params
      }.not_to change(Document, :count)
    end
  end

  describe "editar los datos de la obra (admin+)" do
    let(:params) { { project: { name: "Obra renombrada" } } }

    %i[owner project_admin].each do |role|
      it "#{role} puede" do
        sign_in_as(public_send(role))

        patch constructors_project_path(project), params: params

        expect(project.reload.name).to eq("Obra renombrada")
      end
    end

    %i[editor viewer].each do |role|
      it "#{role} no puede" do
        sign_in_as(public_send(role))
        original = project.name

        patch constructors_project_path(project), params: params

        expect(project.reload.name).to eq(original)
        expect(response).to have_http_status(:see_other)
      end
    end
  end

  describe "borrar la obra (sólo owner)" do
    it "el owner puede" do
      sign_in_as(owner)

      expect {
        delete constructors_project_path(project)
      }.to change(Project, :count).by(-1)
    end

    it "el admin de obra no puede" do
      sign_in_as(project_admin)

      expect {
        delete constructors_project_path(project)
      }.not_to change(Project, :count)
    end
  end

  describe "alta de personas (admin+)" do
    let(:params) { { project_person: { full_name: "Ana Gómez", status: "active" } } }

    it "el admin de obra puede" do
      sign_in_as(project_admin)

      expect {
        post constructors_project_people_path(project), params: params
      }.to change(ProjectPerson, :count).by(1)
    end

    it "el editor no puede (gestionar equipo es de admin)" do
      sign_in_as(editor)

      expect {
        post constructors_project_people_path(project), params: params
      }.not_to change(ProjectPerson, :count)
    end
  end

  describe "listado de obras" do
    it "incluye las obras donde soy miembro, no sólo las propias" do
      own = create(:project, owner: viewer, name: "Obra propia del viewer")

      sign_in_as(viewer)
      get constructors_projects_path

      expect(response.body).to include(ERB::Util.html_escape(project.name))
      expect(response.body).to include(ERB::Util.html_escape(own.name))
    end

    it "no incluye obras de otro constructor" do
      ajena = create(:project, name: "Obra de otro constructor")

      sign_in_as(viewer)
      get constructors_projects_path

      expect(response.body).not_to include(ERB::Util.html_escape(ajena.name))
    end
  end
end
