# frozen_string_literal: true

# Project header: code badge, status pill, health pill, big title, meta line
# (cliente / ubicación / fechas) and a 5-cell metric strip below.
# Also shows cover photo, días de obra, gastos a la fecha, and % avance.
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
    return "—" if days_to_due.nil?
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

  # Calendar days elapsed since start_date, clamped to >= 0
  def days_in_progress
    return 0 if project.start_date.blank?
    [ (Date.current - project.start_date).to_i, 0 ].max
  end

  # Gastos a la fecha in cents (expenses + approved materials)
  def spent_to_date_cents
    @spent_to_date_cents ||= project.spent_to_date_cents
  end

  # Physical progress percent (0..100)
  def progress_percent
    @progress_percent ||= project.progress_percent
  end

  # Featured image or first image fallback
  def featured_image
    @featured_image ||= project.images.featured.first || project.images.first
  end

  def cover_photo_url
    return unless featured_image&.file&.attached?
    helpers.url_for(featured_image.file)
  end
end
