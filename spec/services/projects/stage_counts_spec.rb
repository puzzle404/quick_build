# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::StageCounts do
  let(:project) { create(:project) }
  let(:stage)   { create(:project_stage, project: project) }
  let(:other)   { create(:project_stage, project: project) }

  # Sólo interesan los COUNT, así que las filas van sin adjunto real.
  def add_documents(owner, n)
    Document.insert_all(Array.new(n) do
      { documentable_type: owner.class.name, documentable_id: owner.id,
        created_at: Time.current, updated_at: Time.current }
    end)
  end

  def add_images(owner, n)
    Image.insert_all(Array.new(n) do
      { imageable_type: owner.class.name, imageable_id: owner.id,
        created_at: Time.current, updated_at: Time.current }
    end)
  end

  describe ".for_project" do
    subject(:counts) { described_class.for_project(project) }

    it "cuenta documentos, fotos y listas de cada etapa" do
      add_documents(stage, 3)
      add_images(stage, 2)
      create(:material_list, project: project, project_stage: stage)

      expect(counts.docs(stage.id)).to eq(3)
      expect(counts.images(stage.id)).to eq(2)
      expect(counts.material_lists(stage.id)).to eq(1)
    end

    it "devuelve 0 para una etapa sin adjuntos" do
      add_documents(stage, 1)

      expect(counts.docs(other.id)).to eq(0)
      expect(counts.images(other.id)).to eq(0)
      expect(counts.material_lists(other.id)).to eq(0)
    end

    it "no mezcla adjuntos de otra obra ni de otro documentable" do
      add_documents(project, 5) # documentos DE LA OBRA, no de la etapa
      ajena = create(:project_stage)
      add_documents(ajena, 4)

      expect(counts.docs(stage.id)).to eq(0)
      expect(counts.docs(ajena.id)).to eq(0)
    end

    it "resuelve toda la obra en TRES queries, no tres por etapa" do
      stages = create_list(:project_stage, 5, project: project)
      stages.each { |s| add_documents(s, 2); add_images(s, 1) }
      stages.each { |s| create(:material_list, project: project, project_stage: s) }

      counts = described_class.for_project(project)

      queries = count_queries do
        stages.each { |s| [ counts.docs(s.id), counts.images(s.id), counts.material_lists(s.id) ] }
      end

      expect(queries).to eq(3)
    end

    it "no consulta la tabla que nadie mira" do
      add_documents(stage, 1)
      counts = described_class.for_project(project)

      expect(count_queries { counts.docs(stage.id) }).to eq(1)
    end
  end

  describe ".for_stage_ids" do
    it "acota el conteo al set pedido" do
      add_documents(stage, 2)
      add_documents(other, 7)

      counts = described_class.for_stage_ids([ stage.id ])

      expect(counts.docs(stage.id)).to eq(2)
      expect(counts.docs(other.id)).to eq(0)
    end

    it "con un set vacío no toca la base" do
      stage_id = stage.id # fuera del bloque: crearlo también son queries
      counts = described_class.for_stage_ids([])

      expect(count_queries { counts.docs(stage_id) }).to eq(0)
      expect(counts.docs(stage_id)).to eq(0)
    end
  end
end
