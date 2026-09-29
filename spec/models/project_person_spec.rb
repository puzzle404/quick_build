require 'rails_helper'

RSpec.describe ProjectPerson, type: :model do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:person_attendances).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:full_name) }

  describe '#current?' do
    it 'is true when active and end_date not passed' do
      person = build(:project_person, status: :active, end_date: Date.current + 1)
      expect(person.current?).to be(true)
    end
  end
end

