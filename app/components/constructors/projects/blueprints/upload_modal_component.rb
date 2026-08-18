# frozen_string_literal: true

# Modal QB OS para subir un plano sin salir de la vista de Planos.
# Se carga dentro del frame `project_modal` (mismo patrón que Materiales,
# Etapas y Personas); el submit navega a _top para que el redirect de
# blueprints#create vuelva al índice con el plano nuevo seleccionado.
class Constructors::Projects::Blueprints::UploadModalComponent < ViewComponent::Base
  def initialize(project:, blueprint:)
    @project = project
    @blueprint = blueprint
  end

  attr_reader :project, :blueprint
end
