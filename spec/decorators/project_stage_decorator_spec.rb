# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectStageDecorator do
  let(:project) { create(:project) }

  subject(:decorated) { described_class.new(stage) }

  describe "#code" do
    context "when stage is a root stage (no parent)" do
      let(:stage) { create(:project_stage, project: project, position: 3) }

      it "returns the stage position as a string" do
        expect(decorated.code).to eq("3")
      end
    end

    context "when stage has position 1" do
      let(:stage) { create(:project_stage, project: project, position: 1) }

      it "returns '1'" do
        expect(decorated.code).to eq("1")
      end
    end

    context "when stage is a sub-stage (has parent)" do
      let(:parent_stage) { create(:project_stage, project: project, position: 2) }
      let(:stage) do
        create(:project_stage, project: project, parent_id: parent_stage.id, position: 4)
      end

      it "returns 'parent_position.position'" do
        expect(decorated.code).to eq("2.4")
      end
    end

    context "when parent has position 1 and sub-stage has position 1" do
      let(:parent_stage) { create(:project_stage, project: project, position: 1) }
      let(:stage) do
        create(:project_stage, project: project, parent_id: parent_stage.id, position: 1)
      end

      it "returns '1.1'" do
        expect(decorated.code).to eq("1.1")
      end
    end
  end

  describe "#status" do
    context "when progress is 0" do
      let(:stage) { create(:project_stage, project: project, progress: 0) }

      it "returns :pending" do
        expect(decorated.status).to eq(:pending)
      end
    end

    context "when progress is 50" do
      let(:stage) { create(:project_stage, project: project, progress: 50) }

      it "returns :doing" do
        expect(decorated.status).to eq(:doing)
      end
    end

    context "when progress is 100" do
      let(:stage) { create(:project_stage, project: project, progress: 100) }

      it "returns :done" do
        expect(decorated.status).to eq(:done)
      end
    end
  end

  describe "#overdue?" do
    context "when end_date is in the past and progress < 100" do
      let(:stage) do
        create(:project_stage, project: project,
               start_date: 10.days.ago, end_date: 2.days.ago, progress: 50)
      end

      it "returns true" do
        expect(decorated.overdue?).to be true
      end
    end

    context "when progress is 100" do
      let(:stage) do
        create(:project_stage, project: project,
               start_date: 10.days.ago, end_date: 2.days.ago, progress: 100)
      end

      it "returns false" do
        expect(decorated.overdue?).to be false
      end
    end
  end
end
