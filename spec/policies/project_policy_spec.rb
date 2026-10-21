require 'rails_helper'

RSpec.describe ProjectPolicy do
  include_context 'roles de obra'

  let(:record) { project }

  # Crear una obra no depende de ninguna obra: alcanza con ser constructor.
  include_examples 'permiso de obra', :create?,
                   allowed: %i[owner project_admin editor viewer outsider platform_admin]

  include_examples 'permiso de obra', :show?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  include_examples 'permiso de obra', :update?,
                   allowed: %i[owner project_admin platform_admin]

  include_examples 'permiso de obra', :destroy?,
                   allowed: %i[owner platform_admin]

  include_examples 'permiso de obra', :manage_content?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :manage_materials?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :manage_team?,
                   allowed: %i[owner project_admin platform_admin]

  it 'un buyer no puede crear obras' do
    expect(described_class.new(create(:user), record).create?).to be false
  end

  describe 'Scope' do
    let!(:ajena) { create(:project) }

    it 'le da al miembro sus obras y las compartidas, nada más' do
      resolved = described_class::Scope.new(editor, Project).resolve

      expect(resolved).to include(project)
      expect(resolved).not_to include(ajena)
    end

    it 'no le da nada a alguien de afuera' do
      expect(described_class::Scope.new(outsider, Project).resolve).to be_empty
    end

    it 'no le da nada a un usuario anónimo' do
      expect(described_class::Scope.new(nil, Project).resolve).to be_empty
    end

    it 'le da todo al admin de plataforma' do
      expect(described_class::Scope.new(platform_admin, Project).resolve)
        .to include(project, ajena)
    end
  end
end
