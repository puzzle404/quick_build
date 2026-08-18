# frozen_string_literal: true

# Modal centrada para aplicar una plantilla de etapas sobre la obra.
#
# Lista la plantilla base del sistema (sin persistir) + las plantillas
# guardadas por el dueño de la obra. El submit va a stages#apply_template con
# `stage_template_id` (vacío = plantilla base) y los toggles de fechas y
# presupuestos.
class Constructors::Projects::Planning::TemplateModalComponent < ViewComponent::Base
  def initialize(project:)
    @project = project
  end

  attr_reader :project

  # Fuente única: la constante del service. Antes había una copia acá que
  # divergió (le faltaba "Presentación conforme a obra") y el modal mentía
  # sobre lo que iba a crear.
  def base_stages
    ::Constructors::Projects::StageTemplateService::TEMPLATE
  end

  def base_sub_stages_count
    base_stages.sum { |stage| stage.fetch(:sub_stages, []).size }
  end

  # Las plantillas del dueño de la obra: dentro del constructor OS la obra
  # siempre se abre desde `current_user.owned_projects`, así que owner_id es
  # el usuario logueado. Se pasa el id (y no el record) porque el project
  # puede venir decorado.
  def saved_templates
    @saved_templates ||= StageTemplate.owned_by(project.owner_id).ordered.includes(:items).to_a
  end

  def saved_templates?
    saved_templates.any?
  end

  def summary_for(template)
    parts = [ "#{template.root_items_count} etapas" ]
    parts << "#{template.sub_items_count} sub" if template.sub_items_count.positive?
    parts.join(" · ")
  end

  def preview_names(template)
    template.root_items_list.map(&:name)
  end
end
