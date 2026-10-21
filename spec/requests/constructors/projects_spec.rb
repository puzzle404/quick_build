# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Constructors::Projects", type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }

  describe "PATCH /constructors/projects/:id — featured_image swap" do
    before { sign_in(owner) }

    def png_upload
      Rack::Test::UploadedFile.new(
        StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 8),
        "image/png",
        true,
        original_filename: "cover.png"
      )
    end

    def pdf_upload
      Rack::Test::UploadedFile.new(
        StringIO.new("%PDF-1.4 fake"),
        "application/pdf",
        true,
        original_filename: "doc.pdf"
      )
    end

    context "when project has no existing featured image" do
      it "creates a featured image and redirects with notice" do
        expect(project.images.where(featured: true).count).to eq(0)

        patch constructors_project_path(project), params: { featured_image: png_upload }

        expect(response).to redirect_to(constructors_project_path(project))
        follow_redirect!
        expect(response.body).to include("Portada actualizada")

        project.reload
        featured = project.images.where(featured: true)
        expect(featured.count).to eq(1)
      end
    end

    context "when project ALREADY has a featured image (swap)" do
      let!(:old_featured) do
        create(:image, imageable: project, featured: true)
      end

      it "replaces the old featured image with the new one" do
        expect(project.images.where(featured: true).count).to eq(1)

        patch constructors_project_path(project), params: { featured_image: png_upload }

        expect(response).to redirect_to(constructors_project_path(project))
        follow_redirect!
        expect(response.body).to include("Portada actualizada")

        project.reload
        featured = project.images.where(featured: true)
        expect(featured.count).to eq(1)
        expect(featured.first.id).not_to eq(old_featured.id)
        expect(old_featured.reload.featured).to be(false)
      end
    end

    context "when the uploaded file is not an image" do
      let!(:existing_featured) do
        create(:image, imageable: project, featured: true)
      end

      it "does not create a new featured image, redirects with alert, and preserves the old cover" do
        initial_count = project.images.count

        patch constructors_project_path(project), params: { featured_image: pdf_upload }

        expect(response).to redirect_to(constructors_project_path(project))
        follow_redirect!
        expect(response.body).to match(/imagen/i)

        expect(project.images.reload.count).to eq(initial_count)
        expect(project.images.where(featured: true).count).to eq(1)
        expect(existing_featured.reload.featured).to be(true)
      end
    end
  end

  describe "alta de obra" do
    let(:constructor) { create(:user, :constructor) }

    before { sign_in(constructor) }

    it "el select de estado inicial no ofrece Finalizado" do
      get new_constructors_project_path
      expect(response.body).to include(">Inicio</option>")
      expect(response.body).not_to include(">Finalizado</option>")
    end

    it "una obra no puede nacer finalizada aunque se fuerce el parámetro" do
      post constructors_projects_path, params: { project: { name: "Obra X", status: "completed" } }
      expect(constructor.owned_projects.find_by!(name: "Obra X")).to be_planned
    end

    it "guarda el presupuesto en dólares" do
      post constructors_projects_path, params: { project: { name: "Obra USD", budget_currency: "USD", budget_pesos: "50.000" } }

      expect(constructor.owned_projects.find_by!(name: "Obra USD"))
        .to have_attributes(budget_currency: "USD", budget_cents: 5_000_000)
    end

    it "el alta ofrece la moneda del presupuesto" do
      get new_constructors_project_path
      expect(response.body).to include('name="project[budget_currency]"', ">USD</option>")
    end

    it "el alta en el drawer separa los campos en secciones con título propio" do
      get new_constructors_project_path, headers: { "Turbo-Frame" => "drawer" }
      titles = Nokogiri::HTML(body_without_templates).css(".qb-form-section-title").map { _1.text.strip }

      expect(titles).to eq([ "Datos de la obra", "Plazo y presupuesto", "Ubicación de la obra" ])
    end

    it "el alta mobile también ofrece la moneda" do
      cookies["qb_mobile_client"] = "1"
      get new_constructors_project_path
      expect(response.body).to include('name="project[budget_currency]"')
    end
  end

  describe "edición de obra" do
    let(:constructor) { create(:user, :constructor) }
    let(:project) { create(:project, owner: constructor, budget_cents: 1_500_000_00) }

    before { sign_in(constructor) }

    it "permite editar cliente, presupuesto y moneda" do
      get edit_constructors_project_path(project), headers: { "Turbo-Frame" => "drawer" }

      expect(response.body).to include('name="project[client]"', 'name="project[budget_pesos]"', 'name="project[budget_currency]"')
    end

    it "la edición usa títulos de sección, no el estilo de las etiquetas" do
      get edit_constructors_project_path(project), headers: { "Turbo-Frame" => "drawer" }
      titles = Nokogiri::HTML(body_without_templates).css(".qb-form-section-title").map { _1.text.strip }

      expect(titles).to include("Información general", "Ubicación de la obra", "Plazo y presupuesto", "Documentación de soporte")
    end

    it "el edit mobile también ofrece la moneda" do
      cookies["qb_mobile_client"] = "1"
      get edit_constructors_project_path(project)
      expect(response.body).to include('name="project[budget_currency]"')
    end
  end
end
