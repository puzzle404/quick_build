# frozen_string_literal: true

require 'rails_helper'

# Las acciones por fila pasaron de texto ("Ver", "Descargar", "Abrir",
# "Eliminar") a íconos, y las del header del proyecto al kebab. Lo que importa
# no es el glifo sino que no se haya perdido en el camino ningún atributo de
# Turbo ni el nombre accesible.
RSpec.describe 'Constructors · acciones por fila', type: :request do
  let(:owner) { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner, name: 'Obra Testigo') }

  before { sign_in(owner) }

  it 'biblioteca: el ojo abre el visor en el turbo frame y la flecha descarga' do
    doc = project.documents.build
    doc.file.attach(io: StringIO.new('x'), filename: 'planos.pdf', content_type: 'application/pdf')
    doc.save!

    get constructors_library_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-turbo-frame="project_modal"')
    expect(response.body).to include('aria-label="Ver planos.pdf"')
    expect(response.body).to include('aria-label="Descargar planos.pdf"')
  end

  it 'fotos: el tacho sigue siendo un form DELETE con confirmación' do
    create(:image, imageable: project)

    get constructors_project_images_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-turbo-confirm="¿Eliminar esta imagen?"')
    expect(response.body).to include('name="_method" value="delete"')
    expect(response.body).to include('aria-label="Abrir photo.png"')
  end

  it 'header del proyecto: el kebab conserva export CSV, editar y borrar con confirm' do
    # Cualquier sección sirve: el header sale del partial _section_tabs.
    get constructors_project_documents_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('role="menu"')
    expect(response.body).to include(constructors_project_stages_path(project, format: :csv))
    expect(response.body).to include(edit_constructors_project_path(project))
    expect(response.body).to include('data-turbo-method="delete"')
    expect(response.body).to include('¿Eliminar la obra')
    # La primaria queda a la vista, fuera del menú.
    expect(response.body).to include('Registrar gasto')
  end
end
