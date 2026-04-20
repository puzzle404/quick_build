# frozen_string_literal: true

# Centered modal for creating a new MaterialList. 3 source-type buttons
# (Manual / PDF / Excel) plus name, stage, notes. Submits via Turbo to the
# existing material_lists#create.
class Constructors::ProjectsV2::Materials::NewListModalComponent < ViewComponent::Base
  SOURCES = [
    { key: :manual,        label: 'Manual',         icon: :edit, hint: 'Cargar ítems uno por uno' },
    { key: :pdf_upload,    label: 'Importar PDF',   icon: :doc,  hint: 'Detectar con IA' },
    { key: :excel_upload,  label: 'Importar Excel', icon: :grid, hint: 'Mapear columnas' }
  ].freeze

  def initialize(project:)
    @project = project
  end

  attr_reader :project

  def stage_options
    project.project_stages.where(parent_id: nil).order(:position).pluck(:name, :id)
  end
end
