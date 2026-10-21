require 'rails_helper'

RSpec.describe 'QB OS · Documents', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora') }
  before { sign_in_user(user) }

  it 'renders header + tabs + empty state when no documents' do
    visit constructors_project_documents_path(project)
    expect(page).to have_text('Aurora')
    expect(page).to have_text('Etapas')
    expect(page).to have_text('Documentos')
    expect(page).to have_text('Aún no se cargaron documentos.')
  end

  # La subida pasó al drawer (archivos → etapa → Subir): en la pestaña queda
  # el botón que lo abre.
  it 'renders the search field and the upload button' do
    visit constructors_project_documents_path(project)
    expect(page).to have_field('q')
    expect(page).to have_link('Subir documentos', href: new_constructors_project_document_path(project))
  end
end
