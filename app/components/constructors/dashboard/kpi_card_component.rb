# frozen_string_literal: true

module Constructors
  module Dashboard
    class KpiCardComponent < ViewComponent::Base
      def initialize(label:, value:, delta_text: nil, delta_color: :slate)
        @label = label
        @value = value
        @delta_text = delta_text
        @delta_color = delta_color
      end

      private

      attr_reader :label, :value, :delta_text, :delta_color

      def delta_classes
        case delta_color.to_s
        when 'green' then 'text-sm text-green-600'
        when 'red' then 'text-sm text-red-600'
        when 'blue' then 'text-sm text-blue-600'
        else 'text-sm text-slate-500'
        end
      end
    end
  end
end

