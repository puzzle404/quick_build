# frozen_string_literal: true

module Constructors
  module Dashboard
    class ChartPlaceholderComponent < ViewComponent::Base
      def initialize(title: "Evolución mensual", evolution: nil)
        @title = title
        @evolution = evolution
      end

      private

      attr_reader :title, :evolution

      def present?
        evolution.present?
      end

      def values_for(series_key)
        vals = evolution.dig(:series, series_key, :values)
        return Array.new((evolution[:labels] || []).size, 0) if vals.blank?
        vals.map(&:to_i)
      end

      def svg_data_for(series_key, height: 24, bar_w: 6, gap: 6)
        values = values_for(series_key)
        n = [values.size, 6].max
        max_val = [values.max.to_i, 1].max
        # Usamos un sistema donde los centros están en 0, step, 2*step, ... y el ancho incluye media barra a ambos extremos
        step = (bar_w + gap)
        width = (n - 1) * step + bar_w

        bars = values.each_with_index.map do |v, i|
          h = [(v.to_f / max_val) * height, (v > 0 ? 2 : 1)].max.round
          x = i * step
          y = height - h
          { x: x, y: y, h: h }
        end

        { width: width, height: height, bar_w: bar_w, gap: gap, bars: bars }
      end

      def currency(amount_cents)
        helpers.number_to_currency((amount_cents.to_i / 100.0), unit: 'ARS ')
      end
    end
  end
end
