# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::NotesListComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage)   { create(:project_stage, project: project) }

  it "renders the empty state when there are no notes" do
    render_inline described_class.new(notes: [], noteable: project, project: project)
    expect(page).to have_text("Aún no hay notas.")
  end

  it "renders a note body" do
    note = create(:note, noteable: project, author: owner, body: "Revisar instalación eléctrica", title: "Aviso")
    render_inline described_class.new(notes: [ note ], noteable: project, project: project)
    expect(page).to have_text("Revisar instalación eléctrica")
    expect(page).to have_text("Aviso")
  end

  it "renders a note on stage with correct delete path" do
    note = create(:note, noteable: stage, author: owner, body: "Verificar cimientos")
    render_inline described_class.new(notes: [ note ], noteable: stage, project: project)
    expect(page).to have_text("Verificar cimientos")
  end
end
