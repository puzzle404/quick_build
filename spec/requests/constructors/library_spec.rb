# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Constructors::Library', type: :request do
  let(:owner) { create(:user, :constructor) }

  before { sign_in(owner) }

  def build_document(documentable:, filename:, content: "fake content", content_type: "application/pdf")
    doc = documentable.documents.build
    doc.file.attach(
      io: StringIO.new(content),
      filename: filename,
      content_type: content_type
    )
    doc.save!
    doc
  end

  it 'returns 200 and shows documents from owned projects and stages' do
    project = create(:project, owner: owner)
    stage   = create(:project_stage, project: project)

    build_document(documentable: project, filename: "project_level.pdf")
    build_document(documentable: stage, filename: "stage_level.dwg", content_type: "application/octet-stream")

    get constructors_library_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("project_level.pdf")
    expect(response.body).to include("stage_level.dwg")
  end

  it 'does NOT show documents from another user\'s project (tenant scoping)' do
    other_owner   = create(:user, :constructor)
    other_project = create(:project, owner: other_owner)

    build_document(documentable: other_project, filename: "secret_doc.pdf")

    get constructors_library_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("secret_doc.pdf")
  end

  it 'shows the empty state when no documents exist' do
    get constructors_library_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Todavía no hay documentos en tus obras.")
  end

  it 'filters documents by ?q search term' do
    project = create(:project, owner: owner)

    build_document(documentable: project, filename: "planos_generales.pdf")
    build_document(
      documentable: project,
      filename: "presupuesto_final.xlsx",
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )

    get constructors_library_path, params: { q: "planos" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("planos_generales.pdf")
    expect(response.body).not_to include("presupuesto_final.xlsx")
  end
end
