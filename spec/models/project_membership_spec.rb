require 'rails_helper'

RSpec.describe ProjectMembership, type: :model do
  subject { build(:project_membership) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:project_id) }

  describe 'el rol sobrevive al round-trip contra la base' do
    # Con el enum posicional viejo, `role: :editor` se guardaba como "1" en una
    # columna string y volvía como nil: ninguna membresía tenía rol usable.
    %i[viewer editor admin].each do |role|
      it "guarda y relee #{role}" do
        membership = create(:project_membership, role: role)

        expect(membership.reload.role).to eq role.to_s
        expect(described_class.connection.select_value(
          "SELECT role FROM project_memberships WHERE id = #{membership.id}"
        )).to eq role.to_s
      end
    end
  end

  describe '.normalize_role' do
    it 'reconoce los valores actuales' do
      expect(described_class.normalize_role('editor')).to eq :editor
      expect(described_class.normalize_role(:admin)).to eq :admin
    end

    it 'traduce los valores numéricos del enum viejo' do
      expect(described_class.normalize_role('0')).to eq :viewer
      expect(described_class.normalize_role('1')).to eq :editor
      expect(described_class.normalize_role('2')).to eq :admin
    end

    it 'devuelve nil para NULL o basura' do
      expect(described_class.normalize_role(nil)).to be_nil
      expect(described_class.normalize_role('superadmin')).to be_nil
    end
  end

  describe '#effective_role' do
    it 'resuelve la membresía sin rol (data vieja) como viewer' do
      membership = create(:project_membership, role: :editor)
      membership.update_column(:role, nil)

      expect(membership.reload.effective_role).to eq :viewer
    end

    it 'resuelve la membresía con rol numérico viejo' do
      membership = create(:project_membership, role: :viewer)
      membership.update_column(:role, '2')

      expect(membership.reload.effective_role).to eq :admin
    end
  end
end
