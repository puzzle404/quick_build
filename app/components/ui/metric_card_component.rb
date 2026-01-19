# frozen_string_literal: true

module Ui
  class MetricCardComponent < ViewComponent::Base
    # Premium gradient color themes - each creates a distinct visual card
    THEMES = {
      indigo: {
        card_bg: 'bg-gradient-to-br from-indigo-600 via-indigo-700 to-violet-800',
        gradient_bg: 'from-indigo-500/20 to-violet-600/20',
        orb: 'bg-violet-400 opacity-60',
        orb_secondary: 'bg-indigo-400 opacity-40',
        icon_bg: 'bg-white/20',
        title_color: 'text-indigo-200',
        value_color: 'text-white',
        suffix_color: 'text-indigo-200',
        comparison_color: 'text-indigo-200/80',
        progress_label: 'text-indigo-200',
        progress_value: 'text-white',
        progress_track: 'bg-white/20',
        progress_fill: 'bg-gradient-to-r from-white via-indigo-100 to-white',
        footer_bg: 'border-t border-white/10 bg-white/5',
        footer_hover: 'bg-white/10',
        footer_text: 'text-white/90',
        footer_arrow_bg: 'bg-white/20',
        footer_arrow: 'text-white',
        trend_badge: 'bg-white/20 text-white'
      },
      amber: {
        card_bg: 'bg-gradient-to-br from-amber-500 via-orange-500 to-red-500',
        gradient_bg: 'from-yellow-400/20 to-orange-500/20',
        orb: 'bg-yellow-300 opacity-60',
        orb_secondary: 'bg-orange-400 opacity-40',
        icon_bg: 'bg-white/25',
        title_color: 'text-amber-100',
        value_color: 'text-white',
        suffix_color: 'text-amber-100',
        comparison_color: 'text-amber-100/80',
        progress_label: 'text-amber-100',
        progress_value: 'text-white',
        progress_track: 'bg-white/20',
        progress_fill: 'bg-gradient-to-r from-white via-yellow-100 to-white',
        footer_bg: 'border-t border-white/10 bg-white/5',
        footer_hover: 'bg-white/10',
        footer_text: 'text-white/90',
        footer_arrow_bg: 'bg-white/20',
        footer_arrow: 'text-white',
        trend_badge: 'bg-white/20 text-white'
      },
      emerald: {
        card_bg: 'bg-gradient-to-br from-emerald-500 via-emerald-600 to-teal-700',
        gradient_bg: 'from-emerald-400/20 to-teal-500/20',
        orb: 'bg-emerald-300 opacity-60',
        orb_secondary: 'bg-teal-400 opacity-40',
        icon_bg: 'bg-white/25',
        title_color: 'text-emerald-100',
        value_color: 'text-white',
        suffix_color: 'text-emerald-100',
        comparison_color: 'text-emerald-100/80',
        progress_label: 'text-emerald-100',
        progress_value: 'text-white',
        progress_track: 'bg-white/20',
        progress_fill: 'bg-gradient-to-r from-white via-emerald-100 to-white',
        footer_bg: 'border-t border-white/10 bg-white/5',
        footer_hover: 'bg-white/10',
        footer_text: 'text-white/90',
        footer_arrow_bg: 'bg-white/20',
        footer_arrow: 'text-white',
        trend_badge: 'bg-white/20 text-white'
      },
      sky: {
        card_bg: 'bg-gradient-to-br from-sky-500 via-blue-600 to-indigo-700',
        gradient_bg: 'from-sky-400/20 to-blue-500/20',
        orb: 'bg-sky-300 opacity-60',
        orb_secondary: 'bg-blue-400 opacity-40',
        icon_bg: 'bg-white/25',
        title_color: 'text-sky-100',
        value_color: 'text-white',
        suffix_color: 'text-sky-100',
        comparison_color: 'text-sky-100/80',
        progress_label: 'text-sky-100',
        progress_value: 'text-white',
        progress_track: 'bg-white/20',
        progress_fill: 'bg-gradient-to-r from-white via-sky-100 to-white',
        footer_bg: 'border-t border-white/10 bg-white/5',
        footer_hover: 'bg-white/10',
        footer_text: 'text-white/90',
        footer_arrow_bg: 'bg-white/20',
        footer_arrow: 'text-white',
        trend_badge: 'bg-white/20 text-white'
      },
      rose: {
        card_bg: 'bg-gradient-to-br from-rose-500 via-pink-600 to-fuchsia-700',
        gradient_bg: 'from-rose-400/20 to-pink-500/20',
        orb: 'bg-rose-300 opacity-60',
        orb_secondary: 'bg-pink-400 opacity-40',
        icon_bg: 'bg-white/25',
        title_color: 'text-rose-100',
        value_color: 'text-white',
        suffix_color: 'text-rose-100',
        comparison_color: 'text-rose-100/80',
        progress_label: 'text-rose-100',
        progress_value: 'text-white',
        progress_track: 'bg-white/20',
        progress_fill: 'bg-gradient-to-r from-white via-rose-100 to-white',
        footer_bg: 'border-t border-white/10 bg-white/5',
        footer_hover: 'bg-white/10',
        footer_text: 'text-white/90',
        footer_arrow_bg: 'bg-white/20',
        footer_arrow: 'text-white',
        trend_badge: 'bg-white/20 text-white'
      },
      slate: {
        card_bg: 'bg-gradient-to-br from-slate-800 via-slate-900 to-zinc-900',
        gradient_bg: 'from-slate-700/20 to-zinc-800/20',
        orb: 'bg-slate-500 opacity-40',
        orb_secondary: 'bg-zinc-500 opacity-30',
        icon_bg: 'bg-white/15',
        title_color: 'text-slate-300',
        value_color: 'text-white',
        suffix_color: 'text-slate-300',
        comparison_color: 'text-slate-400',
        progress_label: 'text-slate-300',
        progress_value: 'text-white',
        progress_track: 'bg-white/10',
        progress_fill: 'bg-gradient-to-r from-slate-300 via-white to-slate-300',
        footer_bg: 'border-t border-white/5 bg-white/5',
        footer_hover: 'bg-white/10',
        footer_text: 'text-white/80',
        footer_arrow_bg: 'bg-white/15',
        footer_arrow: 'text-white',
        trend_badge: 'bg-white/15 text-white'
      }
    }.freeze

    def initialize(
      title:,
      value:,
      suffix: nil,
      subtitle: nil,
      description: nil,
      comparison: nil,
      icon: nil,
      trend: nil,
      color: :indigo,
      progress: nil,
      chart_data: nil,
      action_path: nil,
      action_label: nil
    )
      @title = title
      @value = value
      @suffix = suffix
      @subtitle = subtitle
      @description = description
      @comparison = comparison
      @icon = icon
      @trend = trend
      @color = color.to_sym
      @progress = progress
      @chart_data = chart_data
      @action_path = action_path
      @action_label = action_label
    end

    # Dynamic class getters for the template
    THEMES.values.first.keys.each do |key|
      define_method("#{key}_class") do
        THEMES.dig(color, key) || THEMES[:indigo][key]
      end
    end

    def show_progress_bar?
      progress.present? && progress.is_a?(Numeric) && progress > 0
    end

    def progress_percentage
      return 0 unless progress
      [[progress.to_i, 0].max, 100].min
    end

    def trend_icon
      return unless trend

      case trend[:direction]
      when :up
        '<svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 17a.75.75 0 01-.75-.75V5.612L5.29 9.77a.75.75 0 01-1.08-1.04l5.25-5.5a.75.75 0 011.08 0l5.25 5.5a.75.75 0 11-1.08 1.04l-3.96-4.158V16.25A.75.75 0 0110 17z" clip-rule="evenodd" /></svg>'
      when :down
        '<svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 3a.75.75 0 01.75.75v10.638l3.96-4.158a.75.75 0 111.08 1.04l-5.25 5.5a.75.75 0 01-1.08 0l-5.25-5.5a.75.75 0 111.08-1.04l3.96 4.158V3.75A.75.75 0 0110 3z" clip-rule="evenodd" /></svg>'
      else
        '<svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M4 10a.75.75 0 01.75-.75h10.5a.75.75 0 010 1.5H4.75A.75.75 0 014 10z" clip-rule="evenodd" /></svg>'
      end.html_safe
    end

    private

    attr_reader :title, :value, :suffix, :subtitle, :description, :comparison,
                :icon, :trend, :color, :progress, :chart_data, :action_path, :action_label
  end
end
