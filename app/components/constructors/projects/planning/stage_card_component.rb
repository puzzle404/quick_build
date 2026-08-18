# frozen_string_literal: true

# Card representation of a root project stage with optional collapsible
# table of sub-stages underneath. Uses qb--expandable controller for collapse.
class Constructors::Projects::Planning::StageCardComponent < ViewComponent::Base
  def initialize(project:, stage:, sub_stages:, expense_totals: nil, stage_counts: nil)
    @project = project
    @stage = stage.is_a?(ProjectStageDecorator) ? stage : ProjectStageDecorator.new(stage)
    @sub_stages = Array(sub_stages).map { |s| s.is_a?(ProjectStageDecorator) ? s : ProjectStageDecorator.new(s) }
    @injected_totals = expense_totals
    @injected_counts = stage_counts
  end

  attr_reader :project, :stage, :sub_stages

  # Se corre con el view context ya disponible (en `initialize` todavía no hay
  # `helpers`, que es de dónde sale el hash del controller).
  def before_render
    stage.attachment_counts = stage_counts
    sub_stages.each do |sub|
      sub.attachment_counts = stage_counts
      # La raíz ya está acá: el "2.1" de la sub-etapa no necesita ir a buscarla.
      sub.parent_stage = stage.object
    end
  end

  # Editar la etapa y crear sub-etapas es editor de obra en adelante
  # (ProjectStagePolicy). Pundit resuelve la policy aunque le pasemos el
  # decorator: Draper hace que `ProjectStage === decorator` sea true.
  def can_edit_stage?
    return @can_edit_stage if defined?(@can_edit_stage)

    @can_edit_stage = helpers.policy(stage).update?
  end

  def status_circle_bg
    case stage.status
    when :done  then "color-mix(in oklab, var(--color-ok) 18%, transparent)"
    when :doing then "color-mix(in oklab, var(--color-accent) 18%, transparent)"
    else             "var(--color-bg-sunken)"
    end
  end

  def status_circle_fg
    case stage.status
    when :done  then "var(--color-ok)"
    when :doing then "var(--color-accent)"
    else             "var(--color-ink-3)"
    end
  end

  def initial_open?
    stage.progress_value.positive? && stage.progress_value < 100
  end

  # Gasto real de la etapa con roll-up de sub-etapas (en centavos). No usa
  # project_stages.spent_cents: esa columna es data de seed que nadie escribe.
  def spent_cents
    @spent_cents ||= stage_ids.sum { |id| expense_totals[id].to_i }
  end

  def spent_pct
    return 0 if stage.budget.zero?

    ((spent_cents.to_f / stage.budget) * 100).round
  end

  def show_spend?
    stage.budget.positive? || spent_cents.positive?
  end

  private

  def stage_ids
    @stage_ids ||= [ stage.id ] + sub_stages.map(&:id)
  end

  # Precomputado (Projects::SpendSummary#by_stage inyectado por el controller)
  # ⇒ 0 queries. Sin inyección, UNA query acotada a esta etapa + sus
  # sub-etapas: nunca una por sub-etapa.
  def expense_totals
    @expense_totals ||= @injected_totals ||
                        controller_totals ||
                        Expense.where(project_stage_id: stage_ids).group(:project_stage_id).sum(:amount_cents)
  end

  # Conteos de adjuntos (docs/fotos/listas) de la etapa y sus sub-etapas.
  # Precomputado por el controller ⇒ 0 queries extra. Sin inyección, TRES
  # queries agrupadas acotadas a este subárbol: nunca tres por fila.
  def stage_counts
    @stage_counts ||= @injected_counts ||
                      controller_counts ||
                      Projects::StageCounts.for_stage_ids(stage_ids)
  end

  # projects#show construye las cards desde la vista (que este componente no
  # controla), así que el hash viaja como assign del controller.
  def controller_totals
    helpers.instance_variable_get(:@stage_expense_totals)
  rescue StandardError
    nil
  end

  def controller_counts
    helpers.instance_variable_get(:@stage_counts)
  rescue StandardError
    nil
  end
end
