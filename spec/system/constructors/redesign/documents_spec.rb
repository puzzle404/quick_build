require 'rails_helper'

RSpec.describe 'QB OS · Documents', type: :system do
  let(:user) { create(:user, :constructor) }
  let(:project) { create(:project, owner: user, name: 'Aurora') }
  before { sign_in_user(user) }

  it 'renders header + tabs + empty state when no documents' do
    visit constructors_project_documents_path(project)
    expect(page).to have_text('Aurora')
    expect(page).to have_text('Resumen')
    expect(page).to have_text('Documentos')
    expect(page).to have_text('Aún no se cargaron documentos.')
  end

  it 'renders the search field and upload form' do
    visit constructors_project_documents_path(project)
    expect(page).to have_field('q')
    expect(page).to have_button('Subir')
  end
end
