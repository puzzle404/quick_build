require 'rails_helper'

RSpec.describe TeamAttendanceStats do
  let(:user)    { create(:user, :constructor) }
  let(:project) { create(:project, owner: user) }

  it 'returns nil avg when there are no people' do
    result = described_class.new(project).call
    expect(result[:avg_attendance_pct]).to be_nil
  end

  it 'leaves hours/cost as nil (schema-bound TODO)' do
    create(:project_person, project: project, status: :active)
    result = described_class.new(project).call
    expect(result[:hours_logged]).to be_nil
    expect(result[:planned_hours]).to be_nil
    expect(result[:labor_cost_cents]).to be_nil
  end

  it 'computes percentage from distinct attendance days' do
    person = create(:project_person, project: project, status: :active)
    # Stub 5 distinct working days in the past 7 days
    5.times { |i| create(:person_attendance, project_person: person, occurred_at: i.days.ago.change(hour: 9)) }
    result = described_class.new(project, window_days: 7).call
    expect(result[:avg_attendance_pct]).to be_a(Integer)
    expect(result[:avg_attendance_pct]).to be > 0
  end

  it 'ignores inactive people' do
    create(:project_person, project: project, status: :inactive)
    result = described_class.new(project).call
    expect(result[:avg_attendance_pct]).to be_nil
  end
end
