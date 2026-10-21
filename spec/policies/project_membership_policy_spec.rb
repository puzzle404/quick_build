require 'rails_helper'

RSpec.describe ProjectMembershipPolicy do
  include_context 'roles de obra'

  let(:record) do
    build(:project_membership, project: project, user: create(:user, :constructor), role: :viewer)
  end

  include_examples 'permiso de obra', :index?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  include_examples 'permiso de obra', :create?,
                   allowed: %i[owner project_admin platform_admin]

  include_examples 'permiso de obra', :destroy?,
                   allowed: %i[owner project_admin platform_admin]

  it 'el editor no puede invitar gente' do
    expect(described_class.new(editor, record).create?).to be false
  end
end
