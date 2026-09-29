# frozen_string_literal: true

# Monogram avatar with deterministic colour based on the name hash.
class Qb::Mobile::AvatarComponent < ViewComponent::Base
  def initialize(name: '??', size: 32)
    @name = name.to_s
    @size = size.to_i
  end

  def call
    parts = @name.split(/\s+/).reject(&:empty?)
    initials = parts.first(2).map { |p| p[0] }.join.upcase
    initials = '??' if initials.empty?
    hash = @name.each_char.sum(&:ord)
    hue = hash % 360
    style = %{width:#{@size}px;height:#{@size}px;font-size:#{(@size * 0.4).round(1)}px;background:oklch(82% 0.045 #{hue});color:oklch(28% 0.06 #{hue})}
    %(<div class="m-avatar" style="#{style}">#{ERB::Util.html_escape(initials)}</div>).html_safe
  end
end
