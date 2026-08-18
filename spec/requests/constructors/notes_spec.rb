# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Notes", type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:other) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage) { create(:project_stage, project: project) }

  let(:valid_params) do
    {
      note: {
        title: "Aviso importante",
        body: "Revisar instalación eléctrica"
      }
    }
  end

  describe "POST project-scoped /constructors/projects/:project_id/notes" do
    context "as project owner" do
      before { sign_in(owner) }

      it "creates a note associated to the project and increments count" do
        expect {
          post constructors_project_notes_path(project), params: valid_params
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.noteable).to eq(project)
        expect(note.author).to eq(owner)
        expect(response).to redirect_to(constructors_project_path(project))
      end
    end

    context "as non-owner" do
      before { sign_in(other) }

      it "is blocked and does not create a note" do
        expect {
          post constructors_project_notes_path(project), params: valid_params
        }.not_to change(Note, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST stage-scoped /constructors/projects/:project_id/stages/:stage_id/notes" do
    context "as project owner" do
      before { sign_in(owner) }

      it "creates a note associated to the stage and increments count" do
        expect {
          post constructors_project_stage_notes_path(project, stage), params: valid_params
        }.to change(Note, :count).by(1)

        note = Note.last
        expect(note.noteable).to eq(stage)
        expect(note.author).to eq(owner)
        expect(response).to redirect_to(constructors_project_stage_path(project, stage, tab: "notas"))
      end
    end
  end

  # Regression guard (final review, fix 1): mismo bug que en gastos — el form
  # vive dentro del frame "drawer", así que un `redirect_to ..., alert:` en la
  # rama de error cerraba el drawer y descartaba el alert junto con lo tipeado.
  describe "POST inválido desde el drawer" do
    before { sign_in(owner) }

    let(:invalid_params) { { note: { title: "Sin cuerpo", body: "" } } }

    # Mismo Accept que manda Turbo al submitear un form dentro de un frame.
    let(:turbo_accept) { "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    it "re-renderiza el form dentro del drawer con 422 en vez de redirigir" do
      expect {
        post constructors_project_notes_path(project),
             params: invalid_params,
             headers: { "Turbo-Frame" => "drawer", "Accept" => turbo_accept }
      }.not_to change(Note, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).not_to be_redirect
      # Tiene que ser HTML, no text/vnd.turbo-stream.html: Turbo procesa una
      # respuesta turbo-stream buscando <turbo-stream> y descartaría el form.
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include('id="drawer"')
      expect(response.body).to include("qb-drawer-panel")
      expect(response.body).to include("No pudimos guardar la nota")
      expect(response.body).to include("Sin cuerpo")
    end

    it "hace lo mismo en la rama de etapa" do
      post constructors_project_stage_notes_path(project, stage),
           params: invalid_params,
           headers: { "Turbo-Frame" => "drawer" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("qb-drawer-panel")
      expect(response.body).to include("No pudimos guardar la nota")
    end

    it "conserva el redirect + alert cuando el POST no viene de un frame (mobile / página completa)" do
      post constructors_project_notes_path(project), params: invalid_params

      expect(response).to redirect_to(constructors_project_path(project))
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET #new sin frame" do
    before { sign_in(owner) }

    it "redirige en vez de servir una página en blanco" do
      get new_constructors_project_note_path(project)

      expect(response).to redirect_to(constructors_project_path(project))
    end

    it "sirve el drawer cuando la request viene del frame" do
      get new_constructors_project_note_path(project), headers: { "Turbo-Frame" => "drawer" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("qb-drawer-panel")
    end
  end

  describe "DELETE project-scoped /constructors/projects/:project_id/notes/:id" do
    before { sign_in(owner) }

    it "destroys the note and decrements count" do
      note = create(:note, noteable: project, author: owner)
      expect {
        delete constructors_project_note_path(project, note)
      }.to change(Note, :count).by(-1)
    end
  end

  describe "DELETE stage-scoped /constructors/projects/:project_id/stages/:stage_id/notes/:id" do
    before { sign_in(owner) }

    it "borra una nota del stage" do
      note = create(:note, noteable: stage, author: owner)
      expect {
        delete constructors_project_stage_note_path(project, stage, note)
      }.to change(Note, :count).by(-1)
    end
  end
end
