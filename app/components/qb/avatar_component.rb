# frozen_string_literal: true

# Monogram avatar — deterministic colour per name via hash → hue.
class Qb::AvatarComponent < ViewComponent::Base
  def initialize(name: '??', size: 22, tone: nil)
    @name = name.to_s.presence || '??'
    @size = size
    @tone = tone
  end

  def call
    parts = @name.split.compact
    initials = if parts.size >= 2
                 parts.first(2).map { |s| s[0] }.join.upcase
               else
                 (parts.first.to_s[0, 2]).upcase
               end
    initials = '?' * 2 if initials.blank?
    hue = @name.bytes.sum % 360
    bg = @tone || "oklch(80% 0.04 #{hue})"
    fg = "oklch(30% 0.06 #{hue})"
    style = "width:#{@size}px;height:#{@size}px;border-radius:999px;display:inline-flex;align-items:center;justify-content:center;background:#{bg};color:#{fg};font-size:#{(@size * 0.42).round}px;font-weight:600;letter-spacing:0.2px;flex-shrink:0;font-family:var(--font-ui);"
    %(<div style="#{style}">#{ERB::Util.html_escape(initials)}</div>).html_safe
  end
end
