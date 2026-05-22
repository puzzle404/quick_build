# frozen_string_literal: true

# Project header: code badge, status pill, health pill, big title, meta line
# (cliente / ubicación / fechas) and a 5-cell metric strip below.
class Constructors::Projects::HeaderComponent < ViewComponent::Base
  def initialize(project:)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
  end

  attr_reader :project

  def health_label
    project.health_label
  end

  def days_to_due
    project.days_to_due
  end

  def days_to_due_label
    return '—' if days_to_due.nil?
    return "Hoy" if days_to_due.zero?
    return "Vencido" if days_to_due.negative?
    days_to_due
  end

  def days_to_due_hint
    project.due_at_label
  end

  def bar_tone
    case project.health
    when :bad then :bad
    when :warn then :warn
    else :accent
    end
  end
end
