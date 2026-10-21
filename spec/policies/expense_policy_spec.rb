require 'rails_helper'

RSpec.describe ExpensePolicy do
  include_context 'roles de obra'

  let(:record) { create(:expense, project: project, author: owner) }

  include_examples 'permiso de obra', :index?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  include_examples 'permiso de obra', :show?,
                   allowed: %i[owner project_admin editor viewer platform_admin]

  include_examples 'permiso de obra', :create?,
                   allowed: %i[owner project_admin editor platform_admin]

  include_examples 'permiso de obra', :destroy?,
                   allowed: %i[owner project_admin editor platform_admin]

  it 'un gasto nuevo sin guardar ya resuelve la obra' do
    expect(described_class.new(editor, project.expenses.build).create?).to be true
  end
end
