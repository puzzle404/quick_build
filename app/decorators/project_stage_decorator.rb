# frozen_string_literal: true

# Adds presentation helpers to ProjectStage so views and components can stay
# free of conditional formatting noise.
class ProjectStageDecorator < BaseDecorator
  delegate_all

  STATUS_LABELS = { done: 'Completada', doing: 'En curso', pending: 'Pendiente' }.freeze

  def code
    object.try(:code).presence || object.position.to_s
  end

  def status
    p = object.progress.to_i
    return :done if p >= 100
    return :doing if p.positive?
    :pending
  end

  def status_label
    STATUS_LABELS[status]
  end

  def status_tone
    { done: :ok, doing: :info, pending: :muted }[status]
  end

  def overdue?
    object.end_date && object.end_date < Date.current && object.progress.to_i < 100
  end

  def days_total
    return nil unless object.start_date && object.end_date
    [(object.end_date - object.start_date).to_i, 0].max
  end

  def lead_label
    object.try(:lead).presence || 'Sin asignar'
  end

  def people_count
    0  # TODO: derive from ProjectPerson association if available
  end

  def docs_count
    object.respond_to?(:documents) ? object.documents.count : 0
  end

  def images_count
    object.respond_to?(:images) ? object.images.count : 0
  end

  def material_lists_count
    object.respond_to?(:material_lists) ? object.material_lists.count : 0
  end

  def budget
    object.try(:budget_cents).to_i
  end

  def spent
    object.try(:spent_cents).to_i
  end

  def spent_pct
    return 0 if budget.zero?
    ((spent.to_f / budget) * 100).round
  end

  def progress_value
    object.progress.to_i
  end

  def start_label
    helpers.qb_fmt_date_short(object.start_date)
  end

  def end_label
    helpers.qb_fmt_date_short(object.end_date)
  end
end
