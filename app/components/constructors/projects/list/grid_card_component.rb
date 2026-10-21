# frozen_string_literal: true

# Project card used in the grid view of the projects list. Shows code, status,
# health dot, name + meta, big progress %, plan diff, bar, and a 2-cell footer
# (budget + team).
class Constructors::Projects::List::GridCardComponent < ViewComponent::Base
  def initialize(project:)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
  end

  attr_reader :project

  # nil sin presupuesto comparable (ver ProjectDecorator#budget_used_pct).
  def used_pct
    project.budget_used_pct
  end

  def bar_tone
    case project.health
    when :bad then :bad
    when :warn then :warn
    else :accent
    end
  end
end
