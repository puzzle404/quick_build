# frozen_string_literal: true

# Detail body of a project stage rendered inside a Turbo Frame ("stage_detail").
# Redesigned to match the DESPUÉS handoff: hero identity block, metrics row,
# sub-stage structure group, and a 5-tab work panel (Materiales/Gastos/Notas/
# Docs/Fotos). Rendered inside the shared drawer shell on the planning view.
class Constructors::Projects::Planning::StageDetailComponent < ViewComponent::Base
  def initialize(project:, stage:, sub_stages: [])
    @project   = project
    @stage     = stage.is_a?(ProjectStageDecorator) ? stage : ProjectStageDecorator.new(stage)
    @sub_stages = Array(sub_stages).map { |s| s.is_a?(ProjectStageDecorator) ? s : ProjectStageDecorator.new(s) }
  end

  attr_reader :project, :stage, :sub_stages

  # ─── Material list helpers ──────────────────────────────────

  def linked_lists
    @linked_lists ||= stage.material_lists.includes(:material_items).to_a
  end

  def list_total_cents(list)
    list.material_items.to_a.sum { |i| (i.quantity.to_f * i.estimated_cost_cents.to_i).round }
  end

  def list_status_tone(list)
    { "draft" => :muted, "ready_for_review" => :warn, "approved" => :ok }[list.status.to_s] || :muted
  end

  def list_status_label(list)
    { "draft" => "Borrador", "ready_for_review" => "Revisión", "approved" => "Aprobada" }[list.status.to_s] || list.status.to_s
  end

  private

  # ─── Status pill tone mapping ───────────────────────────────

  def status_tone
    { done: :ok, doing: :info, pending: :muted }[stage.status] || :muted
  end

  # ─── Progress computation ───────────────────────────────────

  # Weighted-by-duration average of sub-stage progress when sub_stages exist;
  # falls back to the stage's own progress_value when there are no sub-stages.
  def progress_number
    @progress_number ||= begin
      subs = sub_stages
      if subs.empty?
        stage.progress_value
      else
        total_weight  = 0
        weighted_sum  = 0.0
        subs.each do |sub|
          days = sub_duration_days(sub)
          next if days <= 0

          total_weight += days
          weighted_sum += days * (sub.progress_value / 100.0)
        end
        if total_weight.zero?
          # Fall back to simple average when no durations are set
          (subs.sum(&:progress_value).to_f / subs.size).round
        else
          ((weighted_sum / total_weight) * 100).round
        end
      end
    end
  end

  def substage_breakdown
    subs = sub_stages
    return nil if subs.empty?

    done    = subs.count { |s| s.progress_value >= 100 }
    doing   = subs.count { |s| s.progress_value.positive? && s.progress_value < 100 }
    pending = subs.count { |s| s.progress_value.zero? }

    parts = []
    parts << "#{done} completa#{'s' if done != 1}"     if done.positive?
    parts << "#{doing} en curso"                         if doing.positive?
    parts << "#{pending} pendiente#{'s' if pending != 1}" if pending.positive?
    parts.join(" · ").presence
  end

  def sub_duration_days(sub)
    return 0 unless sub.object.start_date && sub.object.end_date

    [ (sub.object.end_date - sub.object.start_date).to_i, 0 ].max
  end
end
