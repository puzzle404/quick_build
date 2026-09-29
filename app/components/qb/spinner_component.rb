# frozen_string_literal: true

# Indicador de carga de QB OS (diseño: artifact "Quick Build · Spinner de
# carga"). Dos variantes con roles distintos:
#   :blocks — cuatro ladrillos que se colocan en orden; la marca de carga
#             (páginas, drawer, paneles).
#   :ring   — anillo; para tamaños chicos (botones, búsquedas inline).
#
#   render Qb::SpinnerComponent.new(variant: :blocks, size: 32, label: "Cargando obra…")
#
# Los colores salen de los tokens (acento sobre línea), así que siguen al
# tema Graphite/Night y al acento elegido por el usuario.
class Qb::SpinnerComponent < ViewComponent::Base
  VARIANTS = %i[blocks ring].freeze

  def initialize(variant: :blocks, size: nil, label: nil, stacked: true)
    @variant = VARIANTS.include?(variant.to_sym) ? variant.to_sym : :blocks
    @size = size || (@variant == :blocks ? 28 : 16)
    @label = label
    @stacked = stacked
  end

  def call
    indicator = @variant == :blocks ? blocks : ring
    return indicator if @label.blank?

    direction = @stacked ? "column" : "row"
    content_tag(:span, role: "status", style: "display:inline-flex;flex-direction:#{direction};align-items:center;gap:#{@stacked ? 14 : 8}px;") do
      safe_join([ indicator, content_tag(:span, @label, class: "qb-spinner-label") ])
    end
  end

  private

  def blocks
    gap = (@size / 9.0).round.clamp(1, 5)
    content_tag(:span, class: "qb-spinner-blocks", style: "--qb-spinner-size:#{@size}px;--qb-spinner-gap:#{gap}px;",
                       "aria-hidden": @label.present? ? "true" : nil, "aria-label": @label.present? ? nil : "Cargando",
                       role: @label.present? ? nil : "status") do
      safe_join(Array.new(4) { tag.span })
    end
  end

  def ring
    stroke = @size >= 28 ? 3 : 2
    content_tag(:span, "", class: "qb-spinner-ring", style: "--qb-spinner-size:#{@size}px;--qb-spinner-stroke:#{stroke}px;",
                           "aria-hidden": @label.present? ? "true" : nil, "aria-label": @label.present? ? nil : "Cargando",
                           role: @label.present? ? nil : "status")
  end
end
