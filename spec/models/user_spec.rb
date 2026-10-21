require 'rails_helper'

RSpec.describe User, type: :model do
  it 'defaults to buyer role' do
    user = build(:user)
    expect(user.role).to eq 'buyer'
  end

  it 'requires a company when role is seller' do
    user = build(:user, :seller, company: nil)
    expect(user).not_to be_valid
    expect(user.errors.of_kind?(:company, :blank)).to be true
  end

  it 'allows a constructor without a company' do
    user = build(:user, :constructor, company: nil)
    expect(user).to be_valid
  end

  it 'allows an admin without a company' do
    admin = build(:user, :admin, company: nil)
    expect(admin).to be_valid
  end

  describe '#accessible_projects' do
    let(:user)    { create(:user, :constructor) }
    let!(:mine)   { create(:project, owner: user) }
    let!(:shared) { create(:project) }
    let!(:ajena)  { create(:project) }

    before { create(:project_membership, project: shared, user: user, role: :editor) }

    it 'suma las propias y las que comparten conmigo' do
      expect(user.accessible_projects).to contain_exactly(mine, shared)
    end

    it 'deja owned_projects como "mis obras", sin las compartidas' do
      expect(user.owned_projects).to contain_exactly(mine)
    end

    it 'no toca obras de otros' do
      expect(user.accessible_projects).not_to include(ajena)
    end
  end

  describe '#project_role_cache' do
    let(:user)    { create(:user, :constructor) }
    let(:project) { create(:project, owner: user) }

    it 'se limpia con reset_project_role_cache!' do
      project.role_for(user)
      expect(user.project_role_cache).to include(project.id => :owner)

      user.reset_project_role_cache!
      expect(user.project_role_cache).to be_empty
    end
  end
end
