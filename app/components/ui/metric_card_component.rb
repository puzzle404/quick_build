# frozen_string_literal: true

module Ui
  class MetricCardComponent < ViewComponent::Base
    def initialize(title:, value:, suffix: nil, description: nil)
      @title = title
      @value = value
      @suffix = suffix
      @description = description
    end

    private

    attr_reader :title, :value, :suffix, :description
  end
end
