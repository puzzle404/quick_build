# frozen_string_literal: true

module Ui
  class SearchFieldComponent < ViewComponent::Base
    def initialize(name:, placeholder:, value: nil, form_action:, param: :q, method: :get, hidden_params: {}, turbo_frame: nil, debounce: 300)
      @name = name
      @placeholder = placeholder
      @value = value
      @form_action = form_action
      @param = param
      @method = method
      @hidden_params = hidden_params.compact_blank
      @turbo_frame = turbo_frame
      @debounce = debounce
    end

    private

    attr_reader :name, :placeholder, :value, :form_action, :param, :method, :hidden_params, :turbo_frame, :debounce
  end
end
