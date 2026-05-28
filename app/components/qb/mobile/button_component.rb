# frozen_string_literal: true

# Pill button — 5 variants × 3 sizes, optional left/right icon.
# Renders <a> when href is present, otherwise <button>.
class Qb::Mobile::ButtonComponent < ViewComponent::Base
  VARIANTS = %i[primary secondary ghost danger fill].freeze
  SIZES = %i[sm md lg].freeze

  def initialize(label = nil, variant: :primary, size: :md, icon: nil, icon_right: nil, href: nil, full: false, type: 'button', data: {}, css_class: nil, aria_label: nil)
    @label = label
    @variant = VARIANTS.include?(variant&.to_sym) ? variant.to_sym : :primary
    @size = SIZES.include?(size&.to_sym) ? size.to_sym : :md
    @icon = icon
    @icon_right = icon_right
    @href = href
    @full = full
    @type = type
    @data = data
    @css_class = css_class
    @aria_label = aria_label
  end

  def call
    classes = ['m-btn']
    classes << "m-btn--#{@variant}" unless @variant == :primary
    classes << 'm-btn--sm' if @size == :sm
    classes << 'm-btn--lg' if @size == :lg
    classes << 'm-btn--full' if @full
    classes << @css_class if @css_class

    label = (@label.presence || content).to_s
    icon_html = @icon ? Qb::Mobile::IconComponent.new(name: @icon, size: 17, stroke: 2.2).call : ''
    icon_right_html = @icon_right ? Qb::Mobile::IconComponent.new(name: @icon_right, size: 17, stroke: 2.2).call : ''
    body = %(#{icon_html}#{label}#{icon_right_html})

    aria = @aria_label || (label.strip.empty? ? @icon&.to_s : nil)
    data_attrs = @data.map { |k, v| %(data-#{k}="#{ERB::Util.html_escape(v)}") }.join(' ')
    aria_attr = aria ? %(aria-label="#{ERB::Util.html_escape(aria)}") : ''

    if @href
      %(<a class="#{classes.join(' ')}" href="#{@href}" #{aria_attr} #{data_attrs}>#{body}</a>).html_safe
    else
      %(<button class="#{classes.join(' ')}" type="#{@type}" #{aria_attr} #{data_attrs}>#{body}</button>).html_safe
    end
  end
end
