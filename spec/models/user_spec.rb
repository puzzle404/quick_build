require 'rails_helper'

RSpec.describe User, type: :model do
  it 'defaults to buyer role' do
    user = build(:user)
    expect(user.role).to eq 'buyer'
  end

  it 'requires a company when role is seller' do
    user = build(:user, :seller, company: nil)
    expect(user).not_to be_valid
    expect(user.errors[:company]).to include("can't be blank")
  end

  it 'allows an admin without a company' do
    admin = build(:user, :admin, company: nil)
    expect(admin).to be_valid
  end
end
