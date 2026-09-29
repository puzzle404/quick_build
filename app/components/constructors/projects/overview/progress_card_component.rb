# frozen_string_literal: true

# Tarjeta "Avance de obra" del panel del proyecto (diseño: artifact "Quick
# Build · Panel de la obra (ronda 2)", estilo tarjetas).
#
# Usa los MISMOS números que el KPI "Avance físico" del header —real =
# `progress_percent` (ponderado por duración de etapa), plan =
# `planned_progress` (lineal entre inicio y entrega)— para que la pantalla
# cuente una sola historia. El `progress_curve` guardado sólo lo escribe el
# seed de demo, así que no se usa: la línea real es una aproximación recta
# desde el inicio hasta el avance de hoy (la app no guarda snapshots
# mensuales), y la del plan es la recta inicio→entrega.
class Constructors::Projects::Overview::ProgressCardComponent < ViewComponent::Base
  W = 350
  H = 70
  TOP = 5
  BOTTOM = 62
  MONTHS = %w[Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic].freeze

  def initialize(project:, today: Date.current)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @today = today
  end

  attr_reader :project, :today

  def real
    @real ||= project.progress_percent.to_i
  end

  def plan
    @plan ||= project.planned_progress.to_i
  end

  def delta
    real - plan
  end

  def delta_label
    return "En plan" if delta.zero?

    "#{delta.positive? ? '+' : '−'}#{delta.abs} pts vs plan"
  end

  def delta_tone
    return :ok if delta >= 0

    delta < -8 ? :bad : :warn
  end

  def chart?
    start_date.present? && end_date.present? && end_date > start_date && today >= start_date
  end

  def plan_points
    pts = [ point(start_date, 0), point(end_date, 100) ]
    pts << point(span_end, 100) if span_end > end_date
    pts.join(" ")
  end

  def real_points
    [ point(start_date, 0), point(today, real) ].join(" ")
  end

  def real_area_points
    "#{point(start_date, 0)} #{point(today, real)} #{x(today)},#{BOTTOM}"
  end

  def today_x
    x(today)
  end

  def today_y
    y(real)
  end

  # Etiquetas del eje: inicio, entrega y "Hoy" (resaltada). Si "Hoy" cae
  # pegada a otra, esa otra se omite para que no se pisen.
  def axis_labels
    labels = [ { text: month(start_date), left: pct(start_date) }, { text: month(end_date), left: pct(end_date) } ]
    today_left = pct(today)
    labels.reject! { |l| (l[:left] - today_left).abs < 12 }
    labels << { text: "Hoy", left: today_left, today: true }
    labels.sort_by { |l| l[:left] }
  end

  private

  def start_date = project.start_date
  def end_date = project.end_date

  def span_end
    [ end_date, today ].max
  end

  def total_days
    (span_end - start_date).to_f
  end

  def x(date)
    ((date - start_date).to_f / total_days * W).round(1)
  end

  def y(value)
    (BOTTOM - (value.to_f.clamp(0, 100) / 100.0 * (BOTTOM - TOP))).round(1)
  end

  def point(date, value)
    "#{x(date)},#{y(value)}"
  end

  def pct(date)
    ((date - start_date).to_f / total_days * 100).clamp(0, 100).round(1)
  end

  def month(date)
    MONTHS[date.month - 1]
  end
end
