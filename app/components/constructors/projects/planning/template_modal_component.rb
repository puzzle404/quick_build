# frozen_string_literal: true

# Centered modal that previews the base stage template (3 root groups +
# their sub-stages) and submits POST to apply_template_constructors_project_stages_path.
class Constructors::Projects::Planning::TemplateModalComponent < ViewComponent::Base
  TEMPLATE = [
    {
      name: 'Proyecto y gestión',
      desc: 'Definición técnica y administrativa del proyecto.',
      subs: ['Estudios preliminares', 'Ante proyecto', 'Proyecto (presentación municipal)', 'Documentación y permisos', '3D y visualizaciones']
    },
    {
      name: 'Dirección de obra',
      desc: 'Coordinación diaria, planos ejecutivos e inspecciones.',
      subs: ['Plan de trabajo', 'Planos ejecutivos por rubros', 'Inspecciones']
    },
    {
      name: 'Administración',
      desc: 'Gestión financiera y contratistas.',
      subs: ['Materiales', 'Mano de obra']
    }
  ].freeze

  def initialize(project:)
    @project = project
  end

  attr_reader :project
end
