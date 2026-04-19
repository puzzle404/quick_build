# frozen_string_literal: true

# Lists known risks/blockers for the project. Until we model them in DB the
# panel either shows the explicit risks passed in, or derives a simple
# "current planned vs real" risk if the project is unhealthy.
class Constructors::ProjectsV2::Overview::RisksPanelComponent < ViewComponent::Base
  def initialize(project:, risks: nil)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @risks = risks
  end

  attr_reader :project

  def items
    return @risks if @risks
    return [] if project.health == :ok
    out = []
    if project.health == :bad
      delta = ((project.spent.to_f / [project.budget, 1].max) * 100 - 100).round
      out << { tone: :bad, title: 'Sobrecosto detectado', body: "Gasto +#{delta}% del presupuesto." }
    end
    if project.planned_progress - project.progress > 8
      out << { tone: :warn, title: 'Avance por debajo del plan',
               body: "Real #{project.progress}% vs plan #{project.planned_progress}%." }
    end
    out
  end
end
