# frozen_string_literal: true

# Tiny coloured dot used in tables and status pills.
class Qb::StatusDotComponent < ViewComponent::Base
  TONES = {
    ok:    'var(--color-ok)',
    warn:  'var(--color-warn)',
    bad:   'var(--color-bad)',
    info:  'var(--color-info)',
    muted: 'var(--color-ink-4)',
  }.freeze

  def initialize(tone: :ok)
    @tone = tone&.to_sym || :muted
  end

  def call
    color = TONES[@tone] || TONES[:muted]
    style = "display:inline-block;width:6px;height:6px;border-radius:999px;background:#{color};box-shadow:0 0 0 3px #{color}22;"
    %(<span style="#{style}"></span>).html_safe
  end
end
