# frozen_string_literal: true

# Pagination footer for Pagy-paginated index views. Renders only when there's
# more than one page. Style matches QB density (28px controls, mono numerals).
class Qb::PaginationComponent < ViewComponent::Base
  def initialize(pagy:, label: 'registros')
    @pagy = pagy
    @label = label
  end

  attr_reader :pagy, :label

  def render?
    pagy.present? && pagy.pages > 1
  end

  def page_link_style(active:)
    base = "min-width:28px;height:28px;padding:0 8px;display:inline-flex;align-items:center;justify-content:center;border-radius:5px;border:1px solid var(--color-line);font-family:var(--font-mono);font-size:12px;text-decoration:none;"
    base + if active
             'background:var(--color-accent);color:var(--color-accent-ink);border-color:var(--color-accent);font-weight:600;'
           else
             'background:var(--color-bg);color:var(--color-ink-2);'
           end
  end

  def disabled_style
    'min-width:28px;height:28px;padding:0 8px;display:inline-flex;align-items:center;justify-content:center;border-radius:5px;border:1px solid var(--color-line);background:var(--color-bg-sunken);color:var(--color-ink-4);font-family:var(--font-mono);font-size:12px;'
  end
end
