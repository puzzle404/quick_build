require 'rails_helper'

RSpec.describe Project, type: :model do
  it { should belong_to(:constructor).class_name('User') }
  it { should validate_presence_of(:name) }
  it { should define_enum_for(:status).with_values(%i[planned in_progress completed]) }
end
