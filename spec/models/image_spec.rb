require 'rails_helper'

RSpec.describe Image, type: :model do
  describe "featured" do
    let(:project) { create(:project) }

    it "permite cero imágenes destacadas" do
      img = create(:image, imageable: project, featured: false)
      expect(img).to be_valid
    end

    it "permite una imagen destacada" do
      img = create(:image, imageable: project, featured: true)
      expect(img).to be_valid
    end

    it "rechaza una segunda imagen destacada para el mismo imageable" do
      create(:image, imageable: project, featured: true)
      second = build(:image, imageable: project, featured: true)
      expect(second).not_to be_valid
      expect(second.errors[:featured]).to include(/ya hay una imagen destacada/i)
    end

    it "permite imágenes destacadas en imageables distintos" do
      stage = create(:project_stage)
      create(:image, imageable: project, featured: true)
      img = create(:image, imageable: stage, featured: true)
      expect(img).to be_valid
    end

    it ".featured devuelve solo las destacadas del scope" do
      destacada = create(:image, imageable: project, featured: true)
      create(:image, imageable: project, featured: false)
      expect(project.images.featured).to contain_exactly(destacada)
    end

    it "permite quitar el destacado de una imagen ya destacada" do
      img = create(:image, imageable: project, featured: true)
      img.featured = false
      expect(img).to be_valid
      expect { img.save! }.not_to raise_error
    end

    it "permite re-guardar la imagen destacada sin conflicto consigo misma" do
      img = create(:image, imageable: project, featured: true)
      img.touch
      expect(img.reload).to be_valid
    end
  end
end
