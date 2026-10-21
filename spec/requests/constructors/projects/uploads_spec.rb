# frozen_string_literal: true

require "rails_helper"

# Subir fotos y documentos de la obra (feedback 21/10): un botón abre el
# drawer; ahí se eligen los archivos y después, opcionalmente, la etapa. El
# "Subir" queda bloqueado hasta elegir algo (data-qb-file-submit lo maneja
# qb--file-field). Antes había un "Subir" suelto en la barra, a la vista
# antes de adjuntar nada.
RSpec.describe "Subida de fotos y documentos de la obra", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let!(:stage) { create(:project_stage, project: project, name: "Replanteo") }
  let(:frame) { { "Turbo-Frame" => "drawer" } }
  let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html, text/html", "Turbo-Frame" => "drawer" } }

  def png
    Rack::Test::UploadedFile.new(StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 8), "image/png", true, original_filename: "obra.png")
  end

  def pdf
    Rack::Test::UploadedFile.new(StringIO.new("%PDF-1.4 fake"), "application/pdf", true, original_filename: "permiso.pdf")
  end

  before { sign_in(constructor) }

  describe "fotos" do
    it "la galería ofrece un botón que abre el drawer, sin form de subida suelto" do
      get constructors_project_images_path(project)
      html = body_without_templates

      expect(html).to include(%(href="#{new_constructors_project_image_path(project)}"))
      expect(html).not_to include('name="image[files][]"')
    end

    it "el drawer pide los archivos, después la etapa, y bloquea Subir hasta elegir" do
      get new_constructors_project_image_path(project), headers: frame
      html = body_without_templates

      expect(html).to include('name="image[files][]"', 'name="image[stage_id]"', "data-qb-file-submit")
      expect(html.index('name="image[files][]"')).to be < html.index('name="image[stage_id]"')
    end

    it "sin frame vuelve a la galería" do
      get new_constructors_project_image_path(project)
      expect(response).to redirect_to(constructors_project_images_path(project))
    end

    it "al subir desde el drawer refresca la página y la foto queda en la etapa elegida" do
      post constructors_project_images_path(project), params: { image: { files: [ png ], stage_id: stage.id } }, headers: turbo

      expect(stage.images.count).to eq(1)
      expect(response.body).to include('action="refresh"')
    end
  end

  describe "documentos" do
    it "la pestaña ofrece un botón que abre el drawer, sin form de subida suelto" do
      get constructors_project_documents_path(project)
      html = body_without_templates

      expect(html).to include(%(href="#{new_constructors_project_document_path(project)}"))
      expect(html).not_to include('name="document[files][]"')
    end

    it "el drawer pide los archivos y la etapa (opcional)" do
      get new_constructors_project_document_path(project), headers: frame

      expect(body_without_templates).to include('name="document[files][]"', 'name="document[stage_id]"', "data-qb-file-submit")
    end

    it "sube un documento vinculado a una etapa y la pestaña lo muestra con la etapa" do
      post constructors_project_documents_path(project), params: { document: { files: [ pdf ], stage_id: stage.id } }, headers: turbo
      expect(stage.documents.count).to eq(1)
      expect(response.body).to include('action="refresh"')

      get constructors_project_documents_path(project)
      expect(response.body).to include("permiso.pdf", "Replanteo")
    end

    it "borra un documento de etapa desde la pestaña de la obra, pero no uno de otra obra" do
      doc = Document.new(documentable: stage)
      doc.file.attach(pdf)
      doc.save!
      foreign = Document.new(documentable: create(:project_stage))
      foreign.file.attach(pdf)
      foreign.save!

      delete constructors_project_document_path(project, doc)
      expect(Document.exists?(doc.id)).to be(false)

      delete constructors_project_document_path(project, foreign)
      expect(response).to have_http_status(:not_found)
      expect(Document.exists?(foreign.id)).to be(true)
    end
  end

  describe "mobile (sin drawer: tarjeta de subida en la misma pantalla)" do
    before { cookies["qb_mobile_client"] = "1" }

    it "fotos: primero los archivos, después la etapa, y Subir bloqueable" do
      get constructors_project_images_path(project)
      html = response.body

      expect(html).to include("data-qb-file-submit", 'data-controller="qb--file-field"')
      expect(html.index('name="image[files][]"')).to be < html.index('name="image[stage_id]"')
    end

    it "documentos: también se puede elegir la etapa" do
      get constructors_project_documents_path(project)
      html = response.body

      expect(html).to include("data-qb-file-submit", 'name="document[stage_id]"')
      expect(html.index('name="document[files][]"')).to be < html.index('name="document[stage_id]"')
    end
  end

  it "los drawers de etapa y la carga de planos también bloquean Subir hasta elegir archivos" do
    get new_constructors_project_stage_image_path(project, stage), headers: frame
    expect(body_without_templates).to include("data-qb-file-submit")

    get new_constructors_project_stage_document_path(project, stage), headers: frame
    expect(body_without_templates).to include("data-qb-file-submit")

    get new_constructors_project_blueprint_path(project), headers: frame
    expect(body_without_templates).to include("data-qb-file-submit")
  end
end
