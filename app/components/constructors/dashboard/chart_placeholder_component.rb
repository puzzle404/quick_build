# frozen_string_literal: true

module Constructors
  module Dashboard
    class ChartPlaceholderComponent < ViewComponent::Base
      def initialize(title: "Evolución mensual", evolution: nil, selected_months: 6)
        @title = title
        @evolution = evolution
        @selected_months = selected_months.to_i
        @selected_months = 6 unless [6, 12].include?(@selected_months)
      end

      private

      attr_reader :title, :evolution, :selected_months

      def present?
        evolution.present?
      end

      def values_for(series_key)
        vals = evolution.dig(:series, series_key, :values)
        return Array.new((evolution[:labels] || []).size, 0) if vals.blank?
        vals.map(&:to_i)
      end

      def currency(amount_cents)
        helpers.number_to_currency((amount_cents.to_i / 100.0), unit: 'ARS ')
      end
    end
  end
end
