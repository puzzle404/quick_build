# frozen_string_literal: true

# Quick Build OS — formatters used across the redesign.
# Currency lives in ARS, dates in es-AR. Keep these tiny and free of state.
module QuickbuildHelper
  # "$ 2.5M" / "$ 45k" / "$ 800" / "—"
  def qb_fmt_ars(cents_or_amount, mode: :auto)
    return '—' if cents_or_amount.nil?
    n = cents_or_amount.to_f
    abs = n.abs
    case mode
    when :compact, :auto
      return "$ #{(n / 1_000_000.0).round(1)}M" if abs >= 1_000_000
      return "$ #{(n / 1_000.0).round}k"        if abs >= 1_000
      "$ #{n.round}"
    when :full
      qb_fmt_ars_full(n)
    end
  end

  # "$ 12.345.678" — Argentina formatting with thousands separator
  def qb_fmt_ars_full(amount)
    return '—' if amount.nil?
    "$ #{amount.round.to_s.reverse.scan(/\d{1,3}/).join('.').reverse}"
  end

  # Cents → ARS short form (handles material totals stored in cents)
  def qb_fmt_cents(cents)
    qb_fmt_ars((cents.to_i / 100.0).round)
  end

  def qb_fmt_pct(value)
    return '—' if value.nil?
    "#{value.round}%"
  end

  ES_MONTHS_SHORT = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze
  private_constant :ES_MONTHS_SHORT

  # "18 abr" — Spanish abbreviated month, no year (matches handoff fmtDate)
  def qb_fmt_date_short(date)
    return '—' if date.blank?
    d = date.to_date
    "#{format('%02d', d.day)} #{ES_MONTHS_SHORT[d.month - 1]}"
  end

  # Tone helpers for ViewComponents — accept symbols or strings
  def qb_tone_class(tone)
    {
      ok:     'text-ok',
      warn:   'text-warn',
      bad:    'text-bad',
      info:   'text-info',
      accent: 'text-accent',
      muted:  'text-ink-3',
    }[tone&.to_sym] || 'text-ink-3'
  end
end
