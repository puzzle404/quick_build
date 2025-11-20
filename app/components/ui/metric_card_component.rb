# frozen_string_literal: true

module Ui
  class MetricCardComponent < ViewComponent::Base
    def initialize(title:, value:, suffix: nil, description: nil, icon: nil, trend: nil, color: :indigo)
      @title = title
      @value = value
      @suffix = suffix
      @description = description
      @icon = icon
      @trend = trend
      @color = color
    end

    def trend_color_class
      return "text-slate-500" unless trend
      
      case trend[:direction]
      when :up then "text-green-600"
      when :down then "text-red-600"
      else "text-slate-500"
      end
    end

    def trend_icon
      return unless trend
      
      case trend[:direction]
      when :up
        '<svg class="h-4 w-4 self-center flex-shrink-0 text-green-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M10 17a.75.75 0 01-.75-.75V5.612L5.29 9.77a.75.75 0 01-1.08-1.04l5.25-5.5a.75.75 0 011.08 0l5.25 5.5a.75.75 0 11-1.08 1.04l-3.96-4.158V16.25A.75.75 0 0110 17z" clip-rule="evenodd" /></svg>'
      when :down
        '<svg class="h-4 w-4 self-center flex-shrink-0 text-red-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M10 3a.75.75 0 01.75.75v10.638l3.96-4.158a.75.75 0 111.08 1.04l-5.25 5.5a.75.75 0 01-1.08 0l-5.25-5.5a.75.75 0 111.08-1.04l3.96 4.158V3.75A.75.75 0 0110 3z" clip-rule="evenodd" /></svg>'
      else
        '<svg class="h-4 w-4 self-center flex-shrink-0 text-slate-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path fill-rule="evenodd" d="M3 10a.75.75 0 01.75-.75h10.638L10.23 5.29a.75.75 0 111.04-1.08l5.5 5.25a.75.75 0 010 1.08l-5.5 5.25a.75.75 0 11-1.04-1.08l4.158-3.96H3.75A.75.75 0 013 10z" clip-rule="evenodd" /></svg>'
      end.html_safe
    end

    private

    attr_reader :title, :value, :suffix, :description, :icon, :trend, :color
  end
end
