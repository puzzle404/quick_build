require 'rails_helper'

RSpec.describe ProjectDecorator do
  let(:project) { create(:project, status: :in_progress, start_date: 30.days.ago, end_date: 30.days.from_now) }
  subject(:decorated) { described_class.new(project) }

  describe '#code' do
    it 'returns "PRJ-NNN" derived from id' do
      allow(project).to receive(:id).and_return(42)
      expect(decorated.code).to eq('PRJ-042')
    end
  end

  describe '#status_label' do
    it 'translates status to Spanish' do
      expect(decorated.status_label).to eq('En obra')
    end
  end

  describe '#status_tone' do
    it 'maps status to a Pill tone symbol' do
      expect(decorated.status_tone).to eq(:info)
    end
  end

  describe '#progress' do
    it 'is 0 when no stages exist' do
      expect(decorated.progress).to eq(0)
    end

    it 'averages root stage progress' do
      create(:project_stage, project: project, position: 1, progress: 80)
      create(:project_stage, project: project, position: 2, progress: 20)
      expect(decorated.progress).to eq(50)
    end

    it 'ignores sub-stages when computing progress' do
      root = create(:project_stage, project: project, position: 1, progress: 50)
      create(:project_stage, project: project, parent_id: root.id, progress: 100)
      expect(decorated.progress).to eq(50)
    end
  end

  describe '#planned_progress' do
    it 'is half the duration when at midpoint' do
      expect(decorated.planned_progress).to be_within(5).of(50)
    end

    it 'is 0 when start_date missing' do
      project.update!(start_date: nil, end_date: nil)
      expect(decorated.planned_progress).to eq(0)
    end
  end

  describe '#health' do
    it 'is :bad when spent overruns budget by more than 10%' do
      project.update!(budget_cents: 100_00)
      create(:project_stage, project: project, spent_cents: 120_00)
      expect(decorated.health).to eq(:bad)
    end

    it 'is :warn when planned progress outpaces actual by more than 8 points' do
      project.update!(start_date: 80.days.ago, end_date: 20.days.from_now)
      create(:project_stage, project: project, progress: 0)
      expect(decorated.health).to eq(:warn)
    end

    it 'is :ok when on track and within budget' do
      project.update!(budget_cents: 1_000_00)
      create(:project_stage, project: project, progress: 50, spent_cents: 100_00)
      expect(decorated.health).to eq(:ok)
    end
  end

  describe '#stages_done' do
    it 'counts root stages at 100%' do
      create(:project_stage, project: project, position: 1, progress: 100)
      create(:project_stage, project: project, position: 2, progress: 60)
      expect(decorated.stages_done).to eq(1)
    end
  end

  describe '#progress_curve_series' do
    it 'returns the stored curve when present' do
      project.update!(progress_curve: [0, 10, 20])
      expect(decorated.progress_curve_series).to eq([0, 10, 20])
    end

    it 'derives a linear ramp when no curve is stored' do
      create(:project_stage, project: project, progress: 60)
      series = decorated.progress_curve_series
      expect(series.first).to eq(0)
      expect(series.last).to eq(60)
    end
  end
end
