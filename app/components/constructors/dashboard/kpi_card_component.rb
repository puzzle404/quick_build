# frozen_string_literal: true

module Constructors
  module Dashboard
    class KpiCardComponent < ViewComponent::Base
      def initialize(label:, value:, delta_text: nil, delta_color: :slate, icon: nil)
        @label = label
        @value = value
        @delta_text = delta_text
        @delta_color = delta_color
        @icon = icon
      end

      def call
        render Ui::MetricCardComponent.new(
          title: label,
          value: value,
          icon: icon,
          trend: trend_data
        )
      end

      private

      attr_reader :label, :value, :delta_text, :delta_color, :icon

      def trend_data
        return unless delta_text.present?

        direction = { 'green' => :up, 'red' => :down }.fetch(delta_color.to_s, :neutral)

        { value: delta_text, direction: direction }
      end
    end
  end
end

