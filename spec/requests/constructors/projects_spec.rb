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
end
