# frozen_string_literal: true

module Constructors
  module Dashboard
    class KpiCardComponent < ViewComponent::Base
      def initialize(
        label:,
        value:,
        delta_text: nil,
        delta_color: :slate,
        icon: nil,
        color: :indigo,
        comparison: nil,      # e.g., "de 10 planeados"
        progress: nil,        # 0-100 percentage
        chart_data: nil,      # Array of values for sparkline
        action_path: nil,
        action_label: nil
      )
        @label = label
        @value = value
        @delta_text = delta_text
        @delta_color = delta_color
        @icon = icon
        @color = color.to_sym
        @comparison = comparison
        @progress = progress
        @chart_data = chart_data
        @action_path = action_path
        @action_label = action_label
      end

      def call
        render Ui::MetricCardComponent.new(
          title: label,
          value: value,
          icon: icon,
          trend: trend_data,
          color: color,
          comparison: comparison,
          progress: progress,
          chart_data: chart_data,
          action_path: action_path,
          action_label: action_label
        )
      end

      private

      attr_reader :label, :value, :delta_text, :delta_color, :icon, :color,
                  :comparison, :progress, :chart_data, :action_path, :action_label

      def trend_data
        return unless delta_text.present?

        direction = { 'green' => :up, 'red' => :down }.fetch(delta_color.to_s, :neutral)

        { value: delta_text, direction: direction }
      end
    end
  end
end
