# frozen_string_literal: true

# Modal centrada para guardar la WBS de la obra como plantilla reutilizable.
#
# Pide nombre + descripción y confirma cuántas etapas se guardan. El submit va
# a stage_templates#create, que delega en StageTemplateCaptureService: las
# fechas se convierten en offsets relativos al inicio de la obra y el progreso
# y el gasto nunca se copian.
class Constructors::Projects::Planning::SaveTemplateModalComponent < ViewComponent::Base
  def initialize(project:)
    @project = project
  end

  attr_reader :project

  def root_stages
    @root_stages ||= project.project_stages.root.ordered.includes(:sub_stages).to_a
  end

  def stages_count
    root_stages.size
  end

  def sub_stages_count
    root_stages.sum { |stage| stage.sub_stages.size }
  end

  def any_stages?
    root_stages.any?
  end

  def summary_line
    parts = [ "#{stages_count} etapa#{'s' if stages_count != 1}" ]
    parts << "#{sub_stages_count} sub-etapa#{'s' if sub_stages_count != 1}" if sub_stages_count.positive?
    parts.join(" y ")
  end

  def default_name
    "Plantilla · #{project.name}".truncate(120)
  end

  # Sin fecha de inicio de obra no hay offsets que calcular: la plantilla se
  # guarda igual, pero sólo con nombres y presupuestos.
  def schedule_warning?
    project.start_date.blank?
  end
end
