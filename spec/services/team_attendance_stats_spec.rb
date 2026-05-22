require 'rails_helper'

RSpec.describe TeamAttendanceStats do
  let(:user)    { create(:user, :constructor) }
  let(:project) { create(:project, owner: user) }

  describe '#avg_attendance_pct' do
    it 'returns nil when there are no people' do
      expect(described_class.new(project).call[:avg_attendance_pct]).to be_nil
    end

    it 'returns 0 when active people exist but no attendances' do
      create(:project_person, project: project, status: :active)
      expect(described_class.new(project).call[:avg_attendance_pct]).to eq(0)
    end

    it 'computes percentage from distinct attendance days' do
      person = create(:project_person, project: project, status: :active)
      5.times { |i| create(:person_attendance, project_person: person, occurred_at: i.days.ago.change(hour: 9)) }
      pct = described_class.new(project, window_days: 7).call[:avg_attendance_pct]
      expect(pct).to be_a(Integer)
      expect(pct).to be > 0
    end

    it 'ignores inactive people' do
      create(:project_person, project: project, status: :inactive)
      expect(described_class.new(project).call[:avg_attendance_pct]).to be_nil
    end
  end

  describe '#hours_logged' do
    it 'sums hours across attendances in window' do
      person = create(:project_person, project: project, status: :active)
      create(:person_attendance, project_person: person, occurred_at: 2.days.ago, hours: 8)
      create(:person_attendance, project_person: person, occurred_at: 1.day.ago, hours: 4.5)
      result = described_class.new(project, window_days: 7).call
      expect(result[:hours_logged]).to eq(12.5)
    end

    it 'returns nil when no records have hours' do
      person = create(:project_person, project: project, status: :active)
      create(:person_attendance, project_person: person, occurred_at: 1.day.ago) # hours nil
      expect(described_class.new(project).call[:hours_logged]).to be_nil
    end
  end

  describe '#planned_hours' do
    it 'is active_count × 8 × working_days_in_window' do
      create(:project_person, project: project, status: :active)
      create(:project_person, project: project, status: :active)
      result = described_class.new(project, window_days: 7).call
      # 7 days back includes ~5 weekdays
      expect(result[:planned_hours]).to be > 0
      expect(result[:planned_hours] % 8).to eq(0) # multiple of 8h
    end

    it 'is nil when no active people' do
      expect(described_class.new(project).call[:planned_hours]).to be_nil
    end
  end

  describe '#labor_cost_cents' do
    it 'sums hours × hourly_rate_cents per attendance' do
      person = create(:project_person, project: project, status: :active, hourly_rate_cents: 5_000_00)
      create(:person_attendance, project_person: person, occurred_at: 1.day.ago, hours: 8)
      create(:person_attendance, project_person: person, occurred_at: 2.days.ago, hours: 4)
      cost = described_class.new(project, window_days: 7).call[:labor_cost_cents]
      expect(cost).to eq((8 + 4) * 5_000_00)
    end

    it 'is nil when no person has both rate and hours' do
      person = create(:project_person, project: project, status: :active) # no rate
      create(:person_attendance, project_person: person, occurred_at: 1.day.ago, hours: 8)
      expect(described_class.new(project).call[:labor_cost_cents]).to be_nil
    end
  end
end
