# frozen_string_literal: true

# Bloque de campos dentro de un form QB OS: titulillo mono en versalitas +
# hairline, los campos, y un footnote opcional con la regla del bloque.
#
# Es el equivalente desktop de Qb::Mobile::FormGroupComponent. Con
# `collapsible: true` se renderiza como <details> para grupos que casi nunca
# se usan (ej. dependencias de etapa), con `open:` decidiendo si arranca
# abierto — importante para que los system specs puedan ver el campo.
class Qb::FormGroupComponent < ViewComponent::Base
  def initialize(title:, subtitle: nil, footnote: nil, collapsible: false, open: true)
    @title = title
    @subtitle = subtitle
    @footnote = footnote
    @collapsible = collapsible
    @open = open
  end

  attr_reader :title, :subtitle, :footnote

  def collapsible?
    @collapsible
  end

  def open?
    @open
  end

  def title_style
    "font-size:10px;font-family:var(--font-mono);text-transform:uppercase;" \
      "letter-spacing:0.7px;color:var(--color-ink-3);"
  end

  def head_style
    "display:flex;align-items:baseline;justify-content:space-between;gap:8px;" \
      "padding-bottom:6px;margin-bottom:12px;border-bottom:1px solid var(--color-line);"
  end
end
