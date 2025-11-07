# frozen_string_literal: true

module Constructors
  module Dashboard
    class ActivityTableComponent < ViewComponent::Base
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

      def status_color_for(entry)
        s = entry[:status].to_s
        return 'text-green-600' if %w[done completed success].include?(s)
        return 'text-red-600' if %w[canceled cancelled error failed].include?(s)
        return 'text-blue-600' if %w[pending in_progress info].include?(s)
        'text-slate-500'
      end
    end
  end
end

