# frozen_string_literal: true

# Compact filter chip with a dropdown of options. Each option is a link to
# the same page with the appropriate query param set, so filtering survives
# Turbo navigation without JS state. The chip highlights when the value is
# not the default (typically "all").
#
# Options: [[value, label], ...]
class Qb::FilterChipComponent < ViewComponent::Base
  def initialize(label:, param:, value:, options:, base_path:, default: 'all', extra_params: {})
    @label = label
    @param = param.to_sym
    @value = value.to_s
    @options = options
    @default = default.to_s
    @base_path = base_path
    @extra_params = extra_params
  end

  attr_reader :label, :param, :value, :options, :default, :base_path, :extra_params

  def current_label
    pair = options.find { |v, _l| v.to_s == value }
    pair ? pair[1] : '—'
  end

  def active?
    value != default
  end

  def url_for_value(v)
    qs = extra_params.merge(param => (v.to_s == default ? nil : v))
    qs = qs.compact
    qs.empty? ? base_path : "#{base_path}?#{qs.to_query}"
  end
end
