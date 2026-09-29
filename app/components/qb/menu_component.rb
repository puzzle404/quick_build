# frozen_string_literal: true

# Kebab / overflow menu primitive. Wraps the `qb--dropdown` Stimulus controller
# (toggle + click afuera + ESC) so el panel vive en UN solo lugar en vez de
# copiarse inline en cada pantalla que necesita un "…".
#
#   render Qb::MenuComponent.new(items: [
#     { label: 'Editar', href: edit_path, icon: :edit },
#     { divider: true },
#     { label: 'Eliminar', href: path, icon: :trash, danger: true,
#       data: { turbo_method: :delete, turbo_confirm: '¿Seguro?' } },
#   ])
#
# Cada item es un Hash:
#   label:    texto (obligatorio salvo divider)
#   href:     destino
#   icon:     símbolo de Qb::IconComponent (opcional)
#   danger:   pinta el item con var(--color-bad)
#   data:     se reenvía VERBATIM al <a> / <button> — Turbo lee de ahí
#             data-turbo-method / data-turbo-confirm / data-turbo-frame / data-turbo
#   method:   si viene, el item se renderiza como button_to (form real, anda sin JS)
#   title:, target:, divider:
#
# Los items pueden ser nil para poder inlinear guards de policy; si no sobrevive
# ninguno el menú entero no se renderiza.
class Qb::MenuComponent < ViewComponent::Base
  # Separación del panel respecto del trigger, según la altura del botón.
  TRIGGER_OFFSETS = { xs: 28, sm: 32, md: 36 }.freeze

  def initialize(items:, label: nil, icon: :more, aria_label: "Más acciones", title: nil,
                 align: :right, variant: :secondary, size: :sm, min_width: 180, panel_style: nil)
    @items = normalize(items)
    @label = label
    @icon = icon
    @aria_label = aria_label
    @title = title
    @align = align.to_sym == :left ? :left : :right
    @variant = variant
    @size = size.to_sym
    @min_width = min_width
    @panel_style = panel_style
  end

  attr_reader :items, :label, :icon, :aria_label, :title, :variant, :size

  def render?
    items.any? { |i| !i[:divider] }
  end

  def panel_style
    offset = TRIGGER_OFFSETS[size] || TRIGGER_OFFSETS[:sm]
    [
      "display:none;position:absolute;",
      "top:#{offset}px;#{@align}:0;",
      "z-index:41;min-width:#{@min_width}px;",
      "background:var(--color-bg);border:1px solid var(--color-line);border-radius:6px;",
      "box-shadow:0 8px 20px -4px rgba(0,0,0,0.25);padding:4px;",
      @panel_style
    ].compact.join
  end

  def item_style(item)
    color = item[:danger] ? "var(--color-bad)" : "var(--color-ink)"
    "display:flex;align-items:center;gap:8px;width:100%;box-sizing:border-box;" \
      "padding:7px 10px;border:none;background:transparent;border-radius:4px;" \
      "color:#{color};font-size:12px;font-family:inherit;font-weight:400;" \
      "text-align:left;text-decoration:none;white-space:nowrap;cursor:pointer;"
  end

  # Hover sin CSS global: mismo patrón inline que usan las tablas del proyecto.
  def hover_attrs
    { onmouseover: "this.style.background='var(--color-bg-sunken)'",
      onmouseout: "this.style.background='transparent'" }
  end

  private

  # Saca los nil (guards de policy) y los separadores que quedaron sueltos al
  # principio, al final o pegados entre sí.
  def normalize(items)
    list = Array(items).compact
    list = list.drop_while { |i| i[:divider] }
    list = list.reverse.drop_while { |i| i[:divider] }.reverse
    list.chunk_while { |a, b| a[:divider] && b[:divider] }.map(&:first)
  end
end
