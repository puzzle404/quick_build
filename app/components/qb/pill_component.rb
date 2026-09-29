# frozen_string_literal: true

# Small caps status pill — flat, borderless, paint-tinted background.
class Qb::PillComponent < ViewComponent::Base
  TONES = {
    ok:     { bg: 'color-mix(in oklab, var(--color-ok) 14%, transparent)',     fg: 'var(--color-ok)' },
    warn:   { bg: 'color-mix(in oklab, var(--color-warn) 18%, transparent)',   fg: 'var(--color-warn)' },
    bad:    { bg: 'color-mix(in oklab, var(--color-bad) 16%, transparent)',    fg: 'var(--color-bad)' },
    info:   { bg: 'color-mix(in oklab, var(--color-info) 14%, transparent)',   fg: 'var(--color-info)' },
    accent: { bg: 'color-mix(in oklab, var(--color-accent) 14%, transparent)', fg: 'var(--color-accent)' },
    muted:  { bg: 'var(--color-bg-sunken)',                                    fg: 'var(--color-ink-3)' },
  }.freeze

  def initialize(label = nil, tone: :ok, mono: false, compact: false)
    @label = label
    @tone = tone&.to_sym || :muted
    @mono = mono
    @compact = compact
  end

  def call
    palette = TONES[@tone] || TONES[:muted]
    pad = @compact ? '1px 6px' : '2px 8px'
    family = @mono ? 'var(--font-mono)' : 'inherit'
    body = (@label.presence || content).to_s
    style = "display:inline-flex;align-items:center;gap:4px;padding:#{pad};font-size:11px;font-weight:500;letter-spacing:0.2px;border-radius:4px;background:#{palette[:bg]};color:#{palette[:fg]};font-family:#{family};white-space:nowrap;line-height:1.5;"
    %(<span style="#{style}">#{body}</span>).html_safe
  end
end
