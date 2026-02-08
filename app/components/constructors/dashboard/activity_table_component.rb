# frozen_string_literal: true

module Constructors
  module Dashboard
    class ActivityTableComponent < ViewComponent::Base
      include ActionView::Helpers::DateHelper

      def initialize(entries: [])
        @entries = entries
      end

      private

      attr_reader :entries

      def status_for(entry)
        status = entry[:status].to_s.presence
        return nil unless status
        status.humanize
      end

      def status_badge_class_for(entry)
        s = entry[:status].to_s
        return 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-600/20' if %w[done completed success].include?(s)
        return 'bg-rose-50 text-rose-700 ring-1 ring-rose-600/20' if %w[canceled cancelled error failed].include?(s)
        return 'bg-sky-50 text-sky-700 ring-1 ring-sky-600/20' if %w[pending in_progress info].include?(s)
        'bg-slate-50 text-slate-600 ring-1 ring-slate-500/10'
      end

      def icon_bg_for(entry)
        type = entry[:type].to_s
        case type
        when 'stage_started', 'stage_completed' then 'bg-indigo-100'
        when 'material_list', 'material' then 'bg-amber-100'
        when 'person', 'attendance' then 'bg-sky-100'
        when 'document' then 'bg-purple-100'
        else 'bg-slate-100'
        end
      end

      def icon_for(entry)
        type = entry[:type].to_s
        svg_class = case type
        when 'stage_started', 'stage_completed' then 'h-5 w-5 text-indigo-600'
        when 'material_list', 'material' then 'h-5 w-5 text-amber-600'
        when 'person', 'attendance' then 'h-5 w-5 text-sky-600'
        when 'document' then 'h-5 w-5 text-purple-600'
        else 'h-5 w-5 text-slate-500'
        end

        case type
        when 'stage_started'
          %(<svg class="#{svg_class}" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z" /></svg>).html_safe
        when 'stage_completed'
          %(<svg class="#{svg_class}" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>).html_safe
        when 'material_list', 'material'
          %(<svg class="#{svg_class}" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z" /></svg>).html_safe
        when 'person', 'attendance'
          %(<svg class="#{svg_class}" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" /></svg>).html_safe
        when 'document'
          %(<svg class="#{svg_class}" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" /></svg>).html_safe
        else
          %(<svg class="#{svg_class}" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>).html_safe
        end
      end
    end
  end
end

