# frozen_string_literal: true

# Bloque de campos dentro de un form QB OS: título de sección + hairline, los
# campos, y un footnote opcional con la regla del bloque. El título usa
# .qb-form-section-title (sans, 13px, semibold): tiene que leerse por encima
# de las etiquetas de los campos (.qb-label, mono en versalitas).
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
end
