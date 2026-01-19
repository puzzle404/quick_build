require 'rails_helper'

RSpec.describe ProjectMembership, type: :model do
  subject { build(:project_membership) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:project_id) }
end
