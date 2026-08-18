module Ui
  class SearchPanelComponent < ViewComponent::Base
    DEFAULT_PLACEHOLDER = "Buscar por nombre, dirección o responsable...".freeze

    def initialize(form_action:, query_param: :q, query_value: nil, placeholder: nil,
                   method: :get, hidden_params: {}, preserve_params: nil, placeholder_rules: nil,
                   turbo_frame: nil, debounce: 300, title: "Buscador", date_filters: {})
      @form_action = form_action
      @query_param = query_param.to_s
      @query_value = query_value
      @method = method
      @turbo_frame = turbo_frame
      @debounce = debounce
      @title = title

      @explicit_hidden = (hidden_params || {}).compact_blank
      @preserve = preserve_params
      @placeholder = placeholder
      @placeholder_rules = placeholder_rules
      @date = build_date_filters(date_filters)
    end

    private

    attr_reader :form_action, :query_param, :query_value, :turbo_frame, :debounce, :title

    def method
      @method
    end

    def date_range_enabled?
      date[:enabled]
    end

    def from_param;  date[:from_param];  end
    def to_param;    date[:to_param];    end
    def from_value;  date[:from_value];  end
    def to_value;    date[:to_value];    end
    def from_label;  date[:from_label];  end
    def to_label;    date[:to_label];    end

    def date
      @date
    end

    def build_date_filters(filters)
      defaults = {
        enabled: false,
        from_param: :from_date,
        to_param: :to_date,
        from_label: "Desde",
        to_label: "Hasta",
        from_value: nil,
        to_value: nil
      }
      incoming = (filters || {})
      merged = defaults.merge(incoming.transform_keys(&:to_sym))
      merged[:enabled] = !!incoming.present? && !!merged[:enabled]
      merged.freeze
    end

    def hidden_params
      @explicit_hidden.merge(preserved_params)
    end

    def preserved_params
      map = preserve_map
      return {} if map.empty?

      map.each_with_object({}) do |(src, dst), out|
        next if src == query_param
        val = request_params[src]
        out[dst] = val if val.present?
      end
    end

    def preserve_map
      rules = @preserve
      case rules
      when Array
        rules.map(&:to_s).zip(rules.map(&:to_s)).to_h
      when Hash
        rules.to_h { |k, v| [k.to_s, (v || k).to_s] }
      else
        {}
      end
    end

    def placeholder_text
      return @placeholder if @placeholder.present?
      rules_text = rules_placeholder
      return rules_text if rules_text.present?
      DEFAULT_PLACEHOLDER
    end

    def rules_placeholder
      rules = @placeholder_rules || {}
      key = rules[:param] || rules["param"]
      return nil if key.blank?

      options = rules[:map] || rules["map"] || {}
      default = rules[:default] || rules["default"]
      current = request_params[key.to_s]
      options[current.to_s] || default
    end

    def request_params
      raw = helpers.params
      hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
      @request_params ||= hash.transform_keys(&:to_s)
    end
  end
end
