# frozen_string_literal: true

module Constructors
  module Dashboard
    class ChartPlaceholderComponent < ViewComponent::Base
      def initialize(title: "Evolución mensual")
        @title = title
      end

      private

      attr_reader :title
    end
  end
end

