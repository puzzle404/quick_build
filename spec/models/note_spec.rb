require 'rails_helper'

RSpec.describe Note, type: :model do
  describe "validations" do
    subject { build(:note, :on_project) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:title).is_at_most(255).allow_blank }
    it { is_expected.to validate_length_of(:body).is_at_most(10_000) }
    it { is_expected.to belong_to(:noteable) }
    it { is_expected.to belong_to(:author).class_name("User") }
  end

  describe "polymorphic" do
    it "puede ser de un Project" do
      project = create(:project)
      note = create(:note, noteable: project)
      expect(project.notes.reload).to include(note)
    end

    it "puede ser de un ProjectStage" do
      stage = create(:project_stage)
      note = create(:note, noteable: stage)
      expect(stage.notes.reload).to include(note)
    end
  end

  describe "scopes" do
    it ".recent_first ordena por created_at descendente" do
      stage = create(:project_stage)
      n1 = create(:note, noteable: stage, created_at: 2.days.ago)
      n2 = create(:note, noteable: stage, created_at: 1.hour.ago)
      expect(stage.notes.recent_first).to eq([ n2, n1 ])
    end
  end
end
