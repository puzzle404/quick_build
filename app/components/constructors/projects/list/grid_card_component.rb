# frozen_string_literal: true

# Project card used in the grid view of the projects list. Shows code, status,
# health dot, name + meta, big progress %, plan diff, bar, and a 2-cell footer
# (budget + team).
class Constructors::Projects::List::GridCardComponent < ViewComponent::Base
  def initialize(project:)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
  end

  attr_reader :project

  def used_pct
    return 0 if project.budget.to_i.zero?
    ((project.spent.to_f / project.budget) * 100).round
  end

  def bar_tone
    case project.health
    when :bad then :bad
    when :warn then :warn
    else :accent
    end
  end
end
