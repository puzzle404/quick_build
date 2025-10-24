require 'rails_helper'

RSpec.describe PersonAttendance, type: :model do
  it { is_expected.to belong_to(:project_person) }
  it { is_expected.to validate_presence_of(:occurred_at) }

  it 'knows when it has coordinates' do
    att = build(:person_attendance, latitude: 1.0, longitude: 2.0)
    expect(att.coordinates?).to be(true)
  end
end

