# frozen_string_literal: true

# Raised card with optional bleed (used as a list container).
class Qb::Mobile::CardComponent < ViewComponent::Base
  def initialize(bleed: false, padding: nil, href: nil, data: {}, css_class: nil)
    @bleed = bleed
    @padding = padding
    @href = href
    @data = data
    @css_class = css_class
  end

  def call
    classes = ['m-card']
    classes << 'm-card--bleed' if @bleed
    classes << @css_class if @css_class
    style = @padding ? %(style="padding:#{@padding}px") : ''
    data = @data.map { |k, v| %(data-#{k}="#{ERB::Util.html_escape(v)}") }.join(' ')

    if @href
      %(<a href="#{@href}" class="#{classes.join(' ')}" #{style} #{data}>#{content}</a>).html_safe
    else
      %(<div class="#{classes.join(' ')}" #{style} #{data}>#{content}</div>).html_safe
    end
  end
end
