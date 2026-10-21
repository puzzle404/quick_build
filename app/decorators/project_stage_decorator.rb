# frozen_string_literal: true

# Adds presentation helpers to ProjectStage so views and components can stay
# free of conditional formatting noise.
class ProjectStageDecorator < BaseDecorator
  delegate_all

  STATUS_LABELS = { done: "Completada", doing: "En curso", pending: "Pendiente" }.freeze

  # Conteos de adjuntos precomputados (un Projects::StageCounts). Inyectarlos
  # deja los tres contadores de la card en CERO queries; sin ellos cada uno
  # resuelve con su propio COUNT, que es lo que necesitan el drawer de etapa y
  # las vistas mobile cuando renderizan una etapa suelta.
  attr_writer :attachment_counts

  # Etapa padre ya cargada. `#code` la usa para el "2.1" de una sub-etapa: sin
  # inyectarla era un SELECT por fila de la tabla de sub-etapas.
  attr_writer :parent_stage

  def code
    if object.parent_id.present?
      "#{parent_stage.position}.#{object.position}"
    else
      object.position.to_s
    end
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
    [ (object.end_date - object.start_date).to_i, 0 ].max
  end

  def lead_label
    object.try(:lead).presence || "Sin asignar"
  end

  def people_count
    0  # TODO: derive from ProjectPerson association if available
  end

  def docs_count
    return @attachment_counts.docs(object.id) if @attachment_counts

    object.respond_to?(:documents) ? object.documents.count : 0
  end

  def images_count
    return @attachment_counts.images(object.id) if @attachment_counts

    object.respond_to?(:images) ? object.images.count : 0
  end

  def material_lists_count
    return @attachment_counts.material_lists(object.id) if @attachment_counts

    object.respond_to?(:material_lists) ? object.material_lists.count : 0
  end

  def budget
    object.try(:budget_cents).to_i
  end

  # OJO: `spent` lee project_stages.spent_cents, que es data de seed —
  # ningún form ni controller de la app la escribe. El gasto real de una etapa
  # sale de sus Expenses (ver #expenses_cents). Las pantallas que todavía usan
  # #spent (drawer de etapa, Gantt, cards mobile) quedan pendientes de migrar.
  def spent
    object.try(:spent_cents).to_i
  end

  def spent_pct
    return 0 if budget.zero?
    ((spent.to_f / budget) * 100).round
  end

  # Gasto real de la etapa, en centavos. +totals+ es el hash
  # {project_stage_id => cents} que devuelve Projects::SpendSummary#by_stage:
  # pasándolo se evita una query por etapa.
  def expenses_cents(totals = nil)
    return totals[object.id].to_i if totals

    @expenses_cents ||= object.expenses.sum(:amount_cents)
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

  private

  # Precomputada (la inyecta StageCardComponent, que ya tiene la raíz en la
  # mano) ⇒ 0 queries. Sin inyección, el `belongs_to` de siempre.
  def parent_stage
    @parent_stage ||= object.parent
  end
end
