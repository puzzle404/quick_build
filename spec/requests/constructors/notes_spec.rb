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
        expect(response).to redirect_to(constructors_project_stage_path(project, stage))
      end
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
