# frozen_string_literal: true

# S-curve: avance real vs plan a lo largo de la vida del proyecto.
# `width`/`height` son las unidades del viewBox: el SVG escala al ancho del
# contenedor, así que un viewBox angosto (rail lateral) mantiene el texto
# legible en vez de encogerlo proporcionalmente.
class Constructors::Projects::Overview::SCurveComponent < ViewComponent::Base
  W = 640
  H = 220
  PAD_L = 44
  PAD_R = 20
  PAD_T = 18
  PAD_B = 26

  def initialize(project:, width: W, height: H)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @data = @project.progress_curve_series
    @plan = @project.progress_plan_series
    @n = [ @data.size, @plan.size ].max
    @w = width
    @h = height
  end

  attr_reader :project, :data, :plan, :n, :w, :h

  def iw; w - PAD_L - PAD_R; end
  def ih; h - PAD_T - PAD_B; end

  def x_at(i)
    PAD_L + (i.to_f / [ n - 1, 1 ].max) * iw
  end

  def y_at(v)
    PAD_T + ih - (v.to_f / 100.0) * ih
  end

  def points(arr)
    arr.each_with_index.map { |v, i| "#{x_at(i).round(1)},#{y_at(v).round(1)}" }.join(" ")
  end

  def plan_area_points
    "#{PAD_L},#{y_at(0)} #{points(plan)} #{x_at(plan.size - 1)},#{y_at(0)}"
  end

  def today_idx
    [ data.size - 1, 0 ].max
  end

  def today_progress
    data[today_idx].to_i
  end

  def today_plan
    plan[today_idx].to_i
  end

  # Las etiquetas de "hoy" van a la izquierda de la línea cuando ésta cae en la
  # mitad derecha; si no, se recortan contra el borde del SVG.
  def today_label_flip?
    x_at(today_idx) > PAD_L + (iw * 0.55)
  end

  def today_label_x
    today_label_flip? ? (x_at(today_idx) - 6).round(1) : (x_at(today_idx) + 6).round(1)
  end

  def today_label_anchor
    today_label_flip? ? "end" : "start"
  end

  # Con viewBox angosto no caben 10 etiquetas de mes: se muestra una de cada dos.
  def month_label_step
    w < 480 && n > 6 ? 2 : 1
  end

  def month_labels
    %w[Nov Dic Ene Feb Mar Abr May Jun Jul Ago].first(n)
  end
end
