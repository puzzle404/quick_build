# frozen_string_literal: true

# Quick Build OS — formatters used across the redesign.
# Currency lives in ARS (project budgets can be USD: see
# Project#budget_ars_cents), dates in es-AR. Keep these tiny and free of state.
module QuickbuildHelper
  CURRENCY_SYMBOLS = { "ARS" => "$", "USD" => "US$" }.freeze

  # "$" / "US$" (lo que no se reconoce cae en pesos).
  def qb_currency_symbol(currency)
    CURRENCY_SYMBOLS.fetch(currency.to_s, "$")
  end

  # "$ 2.5M" / "$ 45k" / "$ 800" / "—" (`symbol:` para otras monedas: "US$ 50k")
  def qb_fmt_ars(cents_or_amount, mode: :auto, symbol: "$")
    return "—" if cents_or_amount.nil?
    n = cents_or_amount.to_f
    abs = n.abs
    case mode
    when :compact, :auto
      return "#{symbol} #{(n / 1_000_000.0).round(1)}M" if abs >= 1_000_000
      return "#{symbol} #{(n / 1_000.0).round}k"        if abs >= 1_000
      "#{symbol} #{n.round}"
    when :full
      qb_fmt_ars_full(n, symbol: symbol)
    end
  end

  # "$ 12.345.678" — Argentina formatting with thousands separator
  def qb_fmt_ars_full(amount, symbol: "$")
    return "—" if amount.nil?
    "#{symbol} #{amount.round.to_s.reverse.scan(/\d{1,3}/).join('.').reverse}"
  end

  # Cents → short form in the given currency (ARS by default)
  def qb_fmt_cents(cents, currency: "ARS", mode: :auto)
    qb_fmt_ars((cents.to_i / 100.0).round, mode: mode, symbol: qb_currency_symbol(currency))
  end

  # Key de navegador de Google Maps (Maps JavaScript API + Places API New).
  # Credentials primero, ENV como alternativa para dev/deploys simples.
  def qb_google_maps_api_key
    Rails.application.credentials.dig(:google_maps, :api_key).presence || ENV["GOOGLE_MAPS_API_KEY"].presence
  end

  # Centro inicial del mapa de una obra todavía sin ubicar: la última obra
  # ubicada del usuario (casi siempre trabaja en la misma zona). nil = el
  # controller project-map usa su centro por defecto.
  #
  # Dos `where.not` encadenados y no `where.not(latitude: nil, longitude: nil)`:
  # con dos claves Rails arma NOT (a AND b) y deja pasar obras con una sola.
  def qb_map_fallback_center
    point = current_user&.accessible_projects
                       &.where&.not(latitude: nil)&.where&.not(longitude: nil)
                       &.reorder(updated_at: :desc)&.pick(:latitude, :longitude)
    point && { lat: point[0], lng: point[1] }
  end

  # Valor inicial de un Qb::MoneyFieldComponent: "1.500" / "1.500,50" (sin "$",
  # que lo pone el componente). Round-trip exacto con Money::ArsParser.
  def qb_money_input_value(cents)
    return nil if cents.blank?

    number_with_precision(cents.to_i / 100.0, precision: (cents.to_i % 100).zero? ? 0 : 2,
                          separator: ",", delimiter: ".")
  end

  def qb_fmt_pct(value)
    return "—" if value.nil?
    "#{value.round}%"
  end

  ES_MONTHS_SHORT = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze
  private_constant :ES_MONTHS_SHORT

  # "18 abr" — Spanish abbreviated month, no year (matches handoff fmtDate)
  def qb_fmt_date_short(date)
    return "—" if date.blank?
    d = date.to_date
    "#{format('%02d', d.day)} #{ES_MONTHS_SHORT[d.month - 1]}"
  end

  # "18 abr 14:30" — fecha corta + hora 24h, para timestamps donde la hora importa
  def qb_fmt_datetime_short(time)
    return "—" if time.blank?
    t = time.in_time_zone
    "#{qb_fmt_date_short(t)} #{t.strftime('%H:%M')}"
  end

  # Tone helpers for ViewComponents — accept symbols or strings
  def qb_tone_class(tone)
    {
      ok:     "text-ok",
      warn:   "text-warn",
      bad:    "text-bad",
      info:   "text-info",
      accent: "text-accent",
      muted:  "text-ink-3"
    }[tone&.to_sym] || "text-ink-3"
  end
end
