# frozen_string_literal: true

require "prawn"
require "prawn/table"

# El texto pasa por #safe (Windows-1252) antes de llegar a Prawn, así que el
# aviso de "fuentes base con soporte limitado de UTF-8" sólo ensucia el log.
Prawn::Fonts::AFM.hide_m17n_warning = true

module Exports
  # PDF de una lista de materiales para pedir cotización a un corralón o
  # proveedor: SIN los precios estimados, que son de uso interno (feedback
  # 29/09). El CSV/Excel los sigue trayendo.
  #
  #   pdf = Exports::MaterialListPdf.new(list)
  #   send_data pdf.render, filename: pdf.filename, type: "application/pdf"
  class MaterialListPdf
    HEADERS = [ "#", "Material", "Descripción", "Cantidad", "Unidad", "Notas" ].freeze

    def initialize(list)
      @list = list
    end

    def render
      pdf = Prawn::Document.new(page_size: "A4", margin: 36, info: { Title: safe(title) })
      header(pdf)
      items_table(pdf)
      pdf.number_pages "Página <page> de <total>", at: [ pdf.bounds.right - 150, -6 ], width: 150,
                                                    align: :right, size: 8, color: "999999"
      pdf.render
    end

    def filename
      slug = [ list.code.presence, list.name.to_s.parameterize.presence ].compact.join("-").downcase
      "materiales-#{slug.presence || list.id}.pdf"
    end

    # Una fila por ítem, en el orden en que se cargaron.
    def rows
      items.each_with_index.map do |item, index|
        [ (index + 1).to_s, safe(item.name), safe(item.description), quantity(item.quantity), safe(item.unit), safe(item.notes) ]
      end
    end

    private

    attr_reader :list

    def items
      @items ||= list.material_items.order(:created_at).to_a
    end

    def title
      "#{list.code} #{list.name}".strip
    end

    def header(pdf)
      pdf.text "Lista de materiales", size: 9, color: "777777"
      pdf.text safe(title), size: 18, style: :bold
      pdf.move_down 4
      meta = [
        "Obra: #{list.project.name}",
        ("Etapa: #{list.project_stage.name}" if list.project_stage),
        "Fecha: #{Date.current.strftime('%d/%m/%Y')}"
      ].compact.join("   ·   ")
      pdf.text safe(meta), size: 9, color: "555555"
      if list.notes.present?
        pdf.move_down 6
        pdf.text safe(list.notes), size: 9
      end
      pdf.move_down 12
    end

    def items_table(pdf)
      if items.empty?
        pdf.text "La lista no tiene ítems.", size: 10, color: "777777"
        return
      end

      pdf.table([ HEADERS ] + rows, header: true, width: pdf.bounds.width,
                cell_style: { size: 9, padding: [ 4, 6 ], border_color: "DDDDDD" },
                column_widths: { 0 => 26, 3 => 62, 4 => 56 }) do |table|
        table.row(0).font_style = :bold
        table.row(0).background_color = "F2F2F2"
        table.column(0).align = :right
        table.column(3).align = :right
      end
    end

    # 12.5 → "12,5"; 10.0 → "10".
    def quantity(value)
      ActiveSupport::NumberHelper.number_to_rounded(value.to_d, precision: 2, strip_insignificant_zeros: true,
                                                                 delimiter: ".", separator: ",")
    end

    # Las fuentes base de Prawn (Helvetica) son Windows-1252: cubren todo el
    # castellano (ñ, tildes, ², ³, ½) pero no emojis ni otros alfabetos, y
    # con esos caracteres Prawn levanta una excepción. Se cambian por "?".
    def safe(text)
      text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end
  end
end
