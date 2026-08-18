# frozen_string_literal: true

# Grilla de datos label/valor (<dl>) — reemplaza los <dl> copiados a mano en
# las fichas de persona y en los detalles de etapa.
#
# items: [{ label:, value:, mono: false, span: 1, href: nil, empty_href: nil,
#           empty_label: 'Cargar' }]
#
# El valor puede venir html_safe (una pill, un link): ERB lo respeta. Si el
# valor está vacío se muestra un guion, salvo que el item traiga `empty_href`,
# en cuyo caso se ofrece el link para cargarlo — que es lo que hace falta
# cuando el dato existe en el modelo pero nadie lo completó.
class Qb::DataGridComponent < ViewComponent::Base
  renders_one :footer

  def initialize(items:, columns: 2, padding: "14px 16px", bordered: true)
    @items = Array(items).compact
    @columns = columns
    @padding = padding
    @bordered = bordered
  end

  attr_reader :items, :columns, :padding

  def any?
    items.any?
  end

  def wrapper_style
    base = "margin:0;padding:#{padding};display:grid;" \
           "grid-template-columns:repeat(#{columns}, minmax(0, 1fr));gap:14px 16px;"
    @bordered ? "#{base}border-bottom:1px solid var(--color-line);" : base
  end

  def dt_style
    "font-size:10px;font-family:var(--font-mono);text-transform:uppercase;" \
      "letter-spacing:0.5px;color:var(--color-ink-4);"
  end

  def dd_style(item)
    base = "margin:3px 0 0;font-size:13px;color:var(--color-ink);"
    item[:mono] ? "#{base}font-family:var(--font-mono);" : base
  end

  def blank_value?(item)
    v = item[:value]
    v.nil? || (v.respond_to?(:strip) && v.strip.empty?)
  end
end
