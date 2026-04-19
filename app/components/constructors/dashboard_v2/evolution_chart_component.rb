# frozen_string_literal: true

# Composite chart: monthly bars (spend) + two lines (real progress vs plan).
# All rendered as inline SVG; no JS dependency. Mirrors EvolutionChart from
# screens/dashboard.jsx.
class Constructors::DashboardV2::EvolutionChartComponent < ViewComponent::Base
  W = 680
  H = 200
  PAD_L = 44
  PAD_R = 60
  PAD_T = 18
  PAD_B = 26

  def initialize(months:, spend:, progress:, plan:)
    @months = Array(months)
    @spend = Array(spend).map(&:to_f)
    @progress = Array(progress).map(&:to_f)
    @plan = Array(plan).map(&:to_f)
  end

  attr_reader :months, :spend, :progress, :plan

  def iw; W - PAD_L - PAD_R; end
  def ih; H - PAD_T - PAD_B; end
  def max_s; [spend.max, 1].compact.max; end

  def x_at(i)
    PAD_L + (i.to_f / [months.size - 1, 1].max) * iw
  end

  def y_bar(v)
    PAD_T + ih - (v / max_s) * ih
  end

  def y_line(v)
    PAD_T + ih - (v / 100.0) * ih
  end

  def line_points(arr)
    arr.each_with_index.map { |v, i| "#{x_at(i).round(1)},#{y_line(v).round(1)}" }.join(' ')
  end

  def progress_area_points
    "#{PAD_L},#{y_line(0)} #{line_points(progress)} #{x_at(progress.size - 1)},#{y_line(0)}"
  end

  def short_ars(n)
    return '0' if n.nil? || n.zero?
    abs = n.abs
    return "$ #{(n / 1_000_000.0).round(1)}M" if abs >= 1_000_000
    return "$ #{(n / 1_000.0).round}k"        if abs >= 1_000
    "$ #{n.to_i}"
  end
end
