# frozen_string_literal: true

module Ui
  class SearchPanelComponent < ViewComponent::Base
    def initialize(form_action:, query_param: :q, query_value: nil, placeholder: "Buscar...",
                   method: :get, hidden_params: {}, turbo_frame: nil, debounce: 300,
                   title: "Buscador", date_filters: {})
      @form_action = form_action
      @query_param = query_param
      @query_value = query_value
      @placeholder = placeholder
      @method = method
      @hidden_params = hidden_params.compact_blank
      @turbo_frame = turbo_frame
      @debounce = debounce
      @title = title
      @date_filters = normalize_date_filters(date_filters)
    end

    private

    attr_reader :form_action, :query_param, :query_value, :placeholder,
                :method, :hidden_params, :turbo_frame, :debounce, :title,
                :date_filters

    def date_range_enabled?
      date_filters.present? && date_filters[:enabled]
    end

    def from_param
      date_filters[:from_param]
    end

    def to_param
      date_filters[:to_param]
    end

    def from_value
      date_filters[:from_value]
    end

    def to_value
      date_filters[:to_value]
    end

    def from_label
      date_filters[:from_label]
    end

    def to_label
      date_filters[:to_label]
    end

    def normalize_date_filters(filters)
      return {} if filters.blank?

      defaults = {
        enabled: true,
        from_param: :from_date,
        to_param: :to_date,
        from_label: "Desde",
        to_label: "Hasta",
        from_value: nil,
        to_value: nil
      }

      defaults.merge(filters.symbolize_keys)
    end
  end
end
