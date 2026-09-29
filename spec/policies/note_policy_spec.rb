require 'rails_helper'

RSpec.describe NotePolicy do
  include_context 'roles de obra'

  context 'nota de la obra' do
    let(:record) { create(:note, noteable: project, author: owner) }

    include_examples 'permiso de obra', :show?,
                     allowed: %i[owner project_admin editor viewer platform_admin]

    include_examples 'permiso de obra', :create?,
                     allowed: %i[owner project_admin editor platform_admin]

    include_examples 'permiso de obra', :destroy?,
                     allowed: %i[owner project_admin editor platform_admin]
  end

  context 'nota de una etapa' do
    let(:stage)  { create(:project_stage, project: project) }
    let(:record) { create(:note, noteable: stage, author: owner) }

    include_examples 'permiso de obra', :create?,
                     allowed: %i[owner project_admin editor platform_admin]
  end

  context 'noteable de un tipo que no conocemos' do
    let(:record) { build(:note, noteable: create(:material_list), author: owner) }

    it 'deniega todo, incluso al owner de esa obra' do
      expect(described_class.new(owner, record).create?).to be false
      expect(described_class.new(owner, record).show?).to be false
    end
  end
end
