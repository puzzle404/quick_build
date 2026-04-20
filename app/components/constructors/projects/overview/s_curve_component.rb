# frozen_string_literal: true

# Big S-curve: real progress vs plan over the lifetime of the project.
class Constructors::Projects::Overview::SCurveComponent < ViewComponent::Base
  W = 640
  H = 220
  PAD_L = 44
  PAD_R = 20
  PAD_T = 18
  PAD_B = 26

  def initialize(project:)
    @project = project.is_a?(ProjectDecorator) ? project : ProjectDecorator.new(project)
    @data = @project.progress_curve_series
    @plan = @project.progress_plan_series
    @n = [@data.size, @plan.size].max
  end

  attr_reader :project, :data, :plan, :n

  def iw; W - PAD_L - PAD_R; end
  def ih; H - PAD_T - PAD_B; end

  def x_at(i)
    PAD_L + (i.to_f / [n - 1, 1].max) * iw
  end

  def y_at(v)
    PAD_T + ih - (v.to_f / 100.0) * ih
  end

  def points(arr)
    arr.each_with_index.map { |v, i| "#{x_at(i).round(1)},#{y_at(v).round(1)}" }.join(' ')
  end

  def plan_area_points
    "#{PAD_L},#{y_at(0)} #{points(plan)} #{x_at(plan.size - 1)},#{y_at(0)}"
  end

  def today_idx
    [data.size - 1, 0].max
  end

  def today_progress
    data[today_idx].to_i
  end

  def today_plan
    plan[today_idx].to_i
  end

  def month_labels
    %w[Nov Dic Ene Feb Mar Abr May Jun Jul Ago].first(n)
  end
end
