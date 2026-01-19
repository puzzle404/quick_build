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
end
