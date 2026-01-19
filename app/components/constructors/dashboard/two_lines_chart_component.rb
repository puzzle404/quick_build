# frozen_string_literal: true

module Constructors
  module Dashboard
    class TwoLinesChartComponent < ViewComponent::Base
      def initialize(evolution:, title: "Evolución mensual")
        @evolution = evolution || {}
        @title = title
      end

      private

      attr_reader :evolution, :title

      def labels
        (evolution[:labels] || []).map(&:to_s)
      end

      def values_for(key)
        (evolution.dig(:series, key, :values) || []).map(&:to_i)
      end

      def json_payload
        {
          labels: labels,
          series: [
            {
              label: 'Etapas iniciadas',
              data: values_for(:stages_started),
              borderColor: '#4f46e5',
              backgroundColor: 'rgba(79, 70, 229, 0.1)'
            },
            {
              label: 'Etapas finalizadas',
              data: values_for(:stages_completed),
              borderColor: '#16a34a',
              backgroundColor: 'rgba(22, 163, 74, 0.1)'
            }
          ]
        }.to_json
      end
    end
  end
end

