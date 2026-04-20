# frozen_string_literal: true

# Right-anchored slide-over with the rich detail of a single stage:
# metrics grid, sub-stages mini-list, linked material lists, document/image
# counts and footer actions. Purely server-rendered HTML (no Turbo Frame
# round-trip) — each card embeds its own drawer so the open/close is local.
class Constructors::Projects::Planning::StageDrawerComponent < ViewComponent::Base
  def initialize(project:, stage:, sub_stages: [])
    @project = project
    @stage = stage.is_a?(ProjectStageDecorator) ? stage : ProjectStageDecorator.new(stage)
    @sub_stages = Array(sub_stages).map { |s| s.is_a?(ProjectStageDecorator) ? s : ProjectStageDecorator.new(s) }
  end

  attr_reader :project, :stage, :sub_stages

  def status_circle_bg
    case stage.status
    when :done  then 'color-mix(in oklab, var(--color-ok) 18%, transparent)'
    when :doing then 'color-mix(in oklab, var(--color-accent) 18%, transparent)'
    else             'var(--color-bg-sunken)'
    end
  end

  def status_circle_fg
    case stage.status
    when :done  then 'var(--color-ok)'
    when :doing then 'var(--color-accent)'
    else             'var(--color-ink-3)'
    end
  end

  def linked_lists
    @linked_lists ||= stage.material_lists.includes(:material_items).to_a
  end

  def list_total_cents(list)
    list.material_items.to_a.sum { |i| (i.quantity.to_f * i.estimated_cost_cents.to_i).round }
  end

  def list_status_tone(list)
    { 'draft' => :muted, 'ready_for_review' => :warn, 'approved' => :ok }[list.status.to_s] || :muted
  end

  def list_status_label(list)
    { 'draft' => 'Borrador', 'ready_for_review' => 'Revisión', 'approved' => 'Aprobada' }[list.status.to_s] || list.status.to_s
  end
end
