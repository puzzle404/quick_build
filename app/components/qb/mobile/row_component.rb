# frozen_string_literal: true

# iOS settings-style row: icon · title/subtitle · value · chevron.
# Renders as `<a>` when `href` is given; falls back to `<div>` otherwise.
class Qb::Mobile::RowComponent < ViewComponent::Base
  def initialize(title:, subtitle: nil, icon: nil, icon_bg: nil, value: nil, value_mono: false, chevron: true, href: nil, data: {})
    @title = title
    @subtitle = subtitle
    @icon = icon
    @icon_bg = icon_bg
    @value = value
    @value_mono = value_mono
    @chevron = chevron
    @href = href
    @data = data
  end

  def call
    icon_html = if @icon
      bg = @icon_bg ? %(style="background:#{@icon_bg}") : ''
      svg = Qb::Mobile::IconComponent.new(name: @icon, size: 17).call
      %(<div class="m-row-icon" #{bg}>#{svg}</div>)
    else
      ''
    end
    subtitle_html = @subtitle ? %(<div class="m-row-subtitle">#{ERB::Util.html_escape(@subtitle)}</div>) : ''
    value_classes = ['m-row-value']
    value_classes << 'm-row-value--mono' if @value_mono
    value_html = @value ? %(<span class="#{value_classes.join(' ')}">#{ERB::Util.html_escape(@value)}</span>) : ''
    chevron_html = @chevron ? %(<span class="m-row-chevron">#{Qb::Mobile::IconComponent.new(name: 'chev-right', size: 16, stroke: 2.2).call}</span>) : ''

    inner = %(#{icon_html}<div class="m-row-main"><div class="m-row-title">#{ERB::Util.html_escape(@title)}</div>#{subtitle_html}</div>#{value_html}#{chevron_html})
    data_attrs = @data.map { |k, v| %(data-#{k}="#{ERB::Util.html_escape(v)}") }.join(' ')

    if @href
      %(<a class="m-row m-row--tap" href="#{@href}" #{data_attrs}>#{inner}</a>).html_safe
    else
      %(<div class="m-row" #{data_attrs}>#{inner}</div>).html_safe
    end
  end
end
