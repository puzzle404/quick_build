# frozen_string_literal: true

class ProjectDecorator < BaseDecorator
  delegate_all

  # ─── Existing helpers ──────────────────────────────────────────

  def total_members
    members.count
  end

  def attachments_count
    object.images.count
  end

  def elapsed_days
    return unless start_date

    [(Date.current - start_date).to_i, 0].max
  end

  def duration_text
    return unless start_date && end_date

    days = (end_date - start_date).to_i + 1
    "#{days} días"
  end

  def duration_hint
    duration_text ? 'Calculado a partir de las fechas de inicio y fin cargadas.' : 'Registra fechas de inicio y fin para calcular la duración estimada.'
  end

  def time_elapsed_hint
    elapsed_days ? 'días desde el inicio' : 'A definir'
  end

  def location_label
    location.presence || 'Ubicación no indicada'
  end

  def coordinates_status
    located? ? 'Coordenadas cargadas' : 'Coordenadas pendientes'
  end

  def coordinates_badge_color
    located? ? 'bg-emerald-500' : 'bg-slate-300'
  end

  def coordinates_label
    return unless located?

    "Lat: #{helpers.number_with_precision(latitude, precision: 4)} · Lng: #{helpers.number_with_precision(longitude, precision: 4)}"
  end

  def member_options
    User.order(:email).map { |user| [user.email, user.id] }
  end

  # ─── Quick Build OS redesign — derived presentation values ─────

  # Project code: e.g. "PRJ-042" — derived from id when not stored.
  def code
    "PRJ-#{object.id.to_s.rjust(3, '0')}"
  end

  # Aggregate physical progress (0..100) from stage rollup.
  def progress
    stages = root_stages
    return 0 if stages.empty?
    (stages.sum { |s| s.progress.to_i } / stages.size).round
  end

  # What the calendar says we *should* have done (linear interpolation).
  def planned_progress
    return 0 unless start_date && end_date
    total = (end_date - start_date).to_f
    return 0 if total <= 0
    elapsed = (Date.current - start_date).to_f
    [[(elapsed / total * 100).round, 0].max, 100].min
  end

  # Simple health heuristic — :ok | :warn | :bad
  def health
    return :bad  if budget.positive? && spent > budget * 1.10
    return :warn if (planned_progress - progress) > 8
    :ok
  end

  def health_label
    { ok: 'Saludable', warn: 'Atención', bad: 'Crítico' }.fetch(health)
  end

  def status_label
    { 'planned' => 'Planificado', 'in_progress' => 'En obra', 'completed' => 'Finalizado' }
      .fetch(object.status.to_s, object.status.to_s.humanize)
  end

  def status_tone
    { 'planned' => :muted, 'in_progress' => :info, 'completed' => :ok }
      .fetch(object.status.to_s, :muted)
  end

  def stages_done
    root_stages.count { |s| s.progress.to_i >= 100 }
  end

  def stages_count
    root_stages.size
  end

  def people_count
    object.respond_to?(:project_people) ? object.project_people.count : 0
  end

  def docs_count
    object.respond_to?(:documents) ? object.documents.count : 0
  end

  def blueprints_count
    object.respond_to?(:blueprints) ? object.blueprints.count : 0
  end

  def materials_count
    object.respond_to?(:material_lists) ? object.material_lists.sum { |ml| ml.material_items.count } : 0
  end

  def budget
    budget_cents.to_i
  end

  def spent
    spent_cents_value
  end

  def committed
    # Placeholder until we have purchase orders modelled.
    (budget * 0.05).to_i
  end

  # Monthly snapshot of real progress; falls back to a linear ramp if not stored.
  def progress_curve_series
    return object.progress_curve if object.progress_curve.present?
    n = curve_buckets
    return [0] if n <= 1
    cur = progress
    (0..n - 1).map { |i| (cur * i.to_f / (n - 1)).round }
  end

  # Monthly snapshot of planned progress; linear if not stored.
  def progress_plan_series
    return object.progress_plan if object.progress_plan.present?
    n = curve_buckets
    return [0] if n <= 1
    plan = planned_progress
    (0..n - 1).map { |i| (plan * i.to_f / (n - 1)).round }
  end

  def days_to_due
    return nil unless end_date
    (end_date - Date.current).to_i
  end

  def started_at_label
    helpers.qb_fmt_date_short(start_date)
  end

  def due_at_label
    helpers.qb_fmt_date_short(end_date)
  end

  private

  # Filter the (often eager-loaded) project_stages association in Ruby instead
  # of issuing a `.where(parent_id: nil)` query per project. When callers do
  # `.includes(:project_stages)` (e.g. the topbar DashboardKpis over all
  # owned projects), this collapses an N+1 into a single stages load.
  def root_stages
    @root_stages ||= object.project_stages.to_a
                           .select { |s| s.parent_id.nil? }
                           .sort_by { |s| s.position.to_i }
  end

  # Sum of stage spend; assumes ProjectStage has spent_cents (added in redesign migration).
  def spent_cents_value
    return 0 unless object.respond_to?(:project_stages)
    object.project_stages.sum { |s| s.try(:spent_cents).to_i }
  end

  def curve_buckets
    return 6 unless start_date
    months = (Date.current.year * 12 + Date.current.month) - (start_date.year * 12 + start_date.month)
    [[months + 1, 2].max, 12].min
  end
end
