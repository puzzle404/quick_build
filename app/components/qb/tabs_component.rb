# frozen_string_literal: true

# Underline-style tabs row with optional right-aligned slot.
class Qb::TabsComponent < ViewComponent::Base
  Tab = Struct.new(:value, :label, :icon, :count, :href, keyword_init: true)

  renders_one :right

  def initialize(tabs:, current:)
    @tabs = tabs.map { |t| t.is_a?(Tab) ? t : Tab.new(**t) }
    @current = current.to_s
  end

  attr_reader :tabs

  def active?(tab)
    tab.value.to_s == @current
  end

  def tab_style(active)
    border = active ? 'var(--color-accent)' : 'transparent'
    color = active ? 'var(--color-ink)' : 'var(--color-ink-3)'
    weight = active ? 600 : 500
    "height:40px;padding:0 12px;background:transparent;border:none;border-bottom:2px solid #{border};color:#{color};font-size:13px;font-weight:#{weight};display:inline-flex;align-items:center;gap:6px;margin-bottom:-1px;text-decoration:none;cursor:pointer;flex-shrink:0;white-space:nowrap;"
  end
end
