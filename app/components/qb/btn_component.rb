# frozen_string_literal: true

# Button primitive with variants/sizes. Renders as <a> when href is given,
# <button> otherwise. The icon is positional (left of label).
class Qb::BtnComponent < ViewComponent::Base
  VARIANTS = {
    primary:   'background:var(--color-accent);color:var(--color-accent-ink);border-color:var(--color-accent);',
    secondary: 'background:var(--color-bg-raised);color:var(--color-ink);border-color:var(--color-line-2);',
    ghost:     'background:transparent;color:var(--color-ink-2);border-color:transparent;',
    danger:    'background:transparent;color:var(--color-bad);border-color:var(--color-line-2);',
  }.freeze

  GHOST_ACTIVE = 'background:var(--color-bg-sunken);color:var(--color-ink);border-color:transparent;'

  SIZES = {
    xs: 'height:24px;padding:0 8px;font-size:11px;',
    sm: 'height:28px;padding:0 10px;font-size:12px;',
    md: 'height:32px;padding:0 12px;font-size:13px;',
  }.freeze

  def initialize(label = nil, variant: :ghost, size: :sm, icon: nil, href: nil, active: false, type: 'button',
                 data: {}, title: nil, css_class: nil, extra_style: nil, target: nil)
    @label = label
    @variant = variant&.to_sym || :ghost
    @size = size&.to_sym || :sm
    @icon = icon
    @href = href
    @active = active
    @type = type
    @data = data
    @title = title
    @css_class = css_class
    @extra_style = extra_style
    @target = target
  end

  def call
    label = (@label.presence || content).to_s
    icon_html = @icon ? Qb::IconComponent.new(name: @icon, size: 13).call : ''.html_safe
    body_html = safe_join([icon_html, label])

    if @href
      link_to @href, **link_opts do
        body_html
      end
    else
      button_tag(body_html, type: @type, title: @title, data: @data, class: @css_class, style: full_style)
    end
  end

  private

  def link_opts
    opts = { style: full_style, class: @css_class, data: @data, title: @title }
    opts[:target] = @target if @target
    opts
  end

  def full_style
    base = 'display:inline-flex;align-items:center;gap:6px;font-weight:500;border-radius:5px;border-width:1px;border-style:solid;font-family:var(--font-ui);white-space:nowrap;cursor:pointer;text-decoration:none;transition:background .15s, border-color .15s, color .15s;'
    variant_style = (@variant == :ghost && @active) ? GHOST_ACTIVE : (VARIANTS[@variant] || VARIANTS[:ghost])
    [base, variant_style, SIZES[@size] || SIZES[:sm], @extra_style].compact.join
  end
end
