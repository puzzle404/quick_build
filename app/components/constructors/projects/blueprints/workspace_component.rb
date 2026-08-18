# frozen_string_literal: true

# Workspace de Planos: lista de planos (248px) + visor real (canvas, escala,
# mediciones) con el panel de Análisis IA apilado en su columna derecha.
#
# Antes esta pantalla era un placeholder con un botón "Abrir viewer" que
# llevaba a blueprints#show. Ahora el visor vive acá: Planos es UNA sola vista.
#
# Los lookups de análisis leen la asociación ya cargada (`includes(:ai_blueprint_analyses)`
# en el controller) para no disparar una query por plano.
class Constructors::Projects::Blueprints::WorkspaceComponent < ViewComponent::Base
  def initialize(project:, blueprints:, selected: nil, construction_items: {})
    @project = project
    @blueprints = blueprints.to_a
    @selected = selected || @blueprints.first
    @construction_items = construction_items
  end

  attr_reader :project, :blueprints, :selected, :construction_items

  # Borrar planos y correr análisis de IA es editor de obra en adelante
  # (ProjectPolicy#manage_content?, lo mismo que piden blueprints#destroy y
  # blueprints/ai_analyses#create).
  def can_manage_content?
    return @can_manage_content if defined?(@can_manage_content)

    @can_manage_content = helpers.policy(project).manage_content?
  end

  def status_label(blueprint)
    last = last_analysis(blueprint)
    case last&.status
    when "completed"  then "Listo"
    when "processing" then "Analizando"
    when "failed"     then "Falló"
    else "Sin IA"
    end
  end

  def status_tone(blueprint)
    case status_label(blueprint)
    when "Listo"      then :ok
    when "Analizando" then :info
    when "Falló"      then :bad
    else :muted
    end
  end

  def analysis?(blueprint)
    completed_analyses(blueprint).any?
  end

  # El shape real que devuelve la IA es
  # { "elements" => [{ "type", "construction_item", "estimated_value", "unit", ... }],
  #   "scale_detected", "scale_notes", "general_notes" }
  # (lib/ai/prompts/blueprint_analyzer.rb). Antes se iteraba como si fuera un
  # hash plano de métricas y escupía el Array entero en una celda.
  def analysis_elements(blueprint)
    elements = last_completed_analysis(blueprint)&.safe_measurements&.dig("elements")
    return [] unless elements.is_a?(Array)

    elements.select { |el| el.is_a?(Hash) }
  end

  def analysis_notes(blueprint)
    last_completed_analysis(blueprint)&.safe_measurements&.dig("general_notes").presence
  end

  def element_label(element)
    element["construction_item"].presence ||
      element["description"].presence ||
      element["type"].to_s.titleize.presence ||
      "Elemento"
  end

  def element_value(element)
    value = element["estimated_value"]
    return "—" if value.blank?

    [ number_with_precision(value.to_f, precision: 2, strip_insignificant_zeros: true),
     element["unit"].presence ].compact.join(" ")
  end

  # Cantidad de grupos de medición ya dibujados sobre el plano.
  def groups_count(blueprint)
    return 0 unless blueprint.measurements.is_a?(Hash)

    (blueprint.measurements["groups"] || blueprint.measurements[:groups] || []).size
  end

  private

  def analyses(blueprint)
    return [] if blueprint.blank?

    blueprint.ai_blueprint_analyses.to_a
  end

  def last_analysis(blueprint)
    analyses(blueprint).max_by { |a| [ a.created_at, a.id ] }
  end

  def completed_analyses(blueprint)
    analyses(blueprint).select { |a| a.status == "completed" }
  end

  def last_completed_analysis(blueprint)
    completed_analyses(blueprint).max_by { |a| [ a.created_at, a.id ] }
  end
end
