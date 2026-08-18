require "rails_helper"

RSpec.describe ProjectStage, type: :model do
  subject(:project_stage) { build(:project_stage) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:material_lists).dependent(:nullify) }
  it { is_expected.to validate_presence_of(:name) }

  describe "date range validation" do
    it "permite rango con fin posterior" do
      project_stage.start_date = Date.current
      project_stage.end_date = Date.current + 5.days

      expect(project_stage).to be_valid
    end

    it "rechaza fin anterior al inicio" do
      project_stage.start_date = Date.current
      project_stage.end_date = Date.current - 1.day

      expect(project_stage).not_to be_valid
      expect(project_stage.errors[:end_date]).to include("debe ser posterior o igual a la fecha de inicio")
    end
  end

  describe "predecessor" do
    let(:project) { create(:project) }
    let!(:stage_a) { create(:project_stage, project: project, start_date: Date.new(2026, 1, 1),  end_date: Date.new(2026, 1, 10)) }
    let!(:stage_b) { create(:project_stage, project: project, start_date: Date.new(2026, 1, 15), end_date: Date.new(2026, 1, 20)) }

    it "permite asignar predecesora del mismo proyecto con fechas válidas" do
      stage_b.predecessor = stage_a
      expect(stage_b).to be_valid
    end

    it "rechaza predecesora de otro proyecto" do
      foreign = create(:project_stage)
      stage_b.predecessor = foreign
      expect(stage_b).not_to be_valid
      expect(stage_b.errors[:predecessor]).to include(/mismo proyecto/i)
    end

    it "rechaza auto-referencia" do
      stage_b.predecessor = stage_b
      expect(stage_b).not_to be_valid
      expect(stage_b.errors[:predecessor]).to include(/no puede ser ella misma/i)
    end

    it "rechaza ciclo (descendiente como predecesora)" do
      stage_a.update_columns(predecessor_id: stage_b.id)
      stage_b.predecessor = stage_a
      expect(stage_b).not_to be_valid
      expect(stage_b.errors[:predecessor]).to include(/ciclo/i)
    end

    it "rechaza start_date antes del end_date de la predecesora" do
      stage_b.update!(start_date: Date.new(2026, 1, 5))
      stage_b.predecessor = stage_a
      expect(stage_b).not_to be_valid
      expect(stage_b.errors[:start_date]).to include(/predecesora/i)
    end

    it "no valida fechas si start_date o predecessor.end_date son nil" do
      stage_b.update_columns(start_date: nil)
      stage_b.predecessor = stage_a
      expect(stage_b).to be_valid
    end

    it "rechaza auto-referencia en un registro nuevo (por objeto)" do
      fresh = build(:project_stage, project: project)
      fresh.predecessor = fresh
      expect(fresh).not_to be_valid
      expect(fresh.errors[:predecessor]).to include(/no puede ser ella misma/i)
    end

    it "detecta ciclos de 3 nodos (A -> B -> C -> A)" do
      a = create(:project_stage, project: project, start_date: Date.new(2026, 3, 1), end_date: Date.new(2026, 3, 5))
      b = create(:project_stage, project: project, start_date: Date.new(2026, 3, 6), end_date: Date.new(2026, 3, 10))
      c = create(:project_stage, project: project, start_date: Date.new(2026, 3, 11), end_date: Date.new(2026, 3, 15))
      b.update_columns(predecessor_id: a.id)
      c.update_columns(predecessor_id: b.id)
      a.predecessor = c
      expect(a).not_to be_valid
      expect(a.errors[:predecessor]).to include(/ciclo/i)
    end
  end
end
