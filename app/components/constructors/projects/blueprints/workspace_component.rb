# frozen_string_literal: true

# 3-column workspace for blueprint analysis: uploads sidebar (280px) +
# viewer placeholder + AI panel (320px). Mirrors screens/blueprints.jsx.
class Constructors::Projects::Blueprints::WorkspaceComponent < ViewComponent::Base
  def initialize(project:, blueprints:, selected: nil)
    @project = project
    @blueprints = blueprints.to_a
    @selected = selected || @blueprints.first
  end

  attr_reader :project, :blueprints, :selected

  def status_label(bp)
    last = bp.ai_blueprint_analyses.recent.first
    return 'En cola'   if last.nil?
    return 'Listo'     if last.status == 'completed'
    return 'Analizando' if last.status == 'processing'
    return 'Falló'     if last.status == 'failed'
    'En cola'
  end

  def status_tone(bp)
    case status_label(bp)
    when 'Listo'      then :ok
    when 'Analizando' then :info
    when 'Falló'      then :bad
    else :muted
    end
  end

  def measurements_for(bp)
    return {} unless bp
    last = bp.ai_blueprint_analyses.completed.recent.first
    return {} unless last
    last.suggested_measurements || {}
  rescue StandardError
    {}
  end

  def has_analysis?(bp)
    bp.ai_blueprint_analyses.completed.any?
  rescue StandardError
    false
  end
end
