# frozen_string_literal: true

require "csv"

module Exports
  # Dialecto ÚNICO de todos los CSV de QuickBuild. Antes había tres (BOM sí/no,
  # separador coma/punto y coma, comillas siempre/nunca) y ninguno abría bien en
  # Excel es-AR. Reglas, todas juntas acá:
  #
  #   * BOM UTF-8    → Excel reconoce los acentos ("Código", "m3") sin importar.
  #   * col_sep ";"  → Excel es-AR usa el separador de lista regional; con ","
  #                    todo el archivo cae en una sola columna.
  #   * decimal ","  → "84500000,00"; sin separador de miles, para que Sheets y
  #                    pandas también lo lean como número.
  #   * fechas dd/mm/aaaa.
  #   * porcentajes enteros SIN "%", plata SIN "$": son números, no texto.
  #   * nil y "" salen igual (celda vacía), nunca conviven ',"",' y ',,'.
  #   * CRLF (RFC 4180).
  #
  # Uso:
  #
  #   Exports::CsvBuilder.generate(["Código", "Obra"]) do |csv|
  #     csv << [project.code, project.name]
  #   end
  #
  # Los formatters son de export, no de UI: qb_fmt_ars devuelve "$ 84.5M" y
  # qb_fmt_date_short "28 nov" (sin año). No sirven para una planilla.
  class CsvBuilder
    BOM = "\uFEFF"
    COL_SEP = ";"
    ROW_SEP = "\r\n"

    # Excel/Sheets evalúan como fórmula toda celda que empieza con estos
    # caracteres. Un proyecto llamado "=SUMA(...)" se convierte en ejecución de
    # contenido del usuario en la máquina de quien abre el archivo.
    FORMULA_PREFIXES = [ "=", "+", "@", "\t", "\r" ].freeze

    def self.generate(headers, &block)
      new(headers).generate(&block)
    end

    def initialize(headers)
      @headers = Array(headers)
    end

    def generate
      body = CSV.generate(col_sep: COL_SEP, row_sep: ROW_SEP) do |csv|
        csv << @headers.map { |header| self.class.cell(header) }
        yield Sink.new(csv)
      end

      BOM + body
    end

    class << self
      # Centavos → "84500000,00"
      def cents(value)
        return nil if value.nil?

        amount(value.to_i / 100.0)
      end

      # Pesos (float/decimal) → "84500000,00"
      def amount(value)
        return nil if value.nil?

        format("%.2f", value.to_f).tr(".", ",")
      end

      # Cantidades: 420.0 → "420", 12.5 → "12,5". Sin ceros de relleno.
      def number(value)
        return nil if value.nil?

        float = value.to_f
        return float.round.to_s if (float - float.round).abs < 1e-9

        float.to_s.tr(".", ",")
      end

      # Porcentaje entero, sin "%": la columna ya lo dice en el encabezado.
      def percent(value)
        return nil if value.nil?

        value.to_f.round.to_s
      end

      def integer(value)
        return nil if value.nil?

        value.to_i.to_s
      end

      # "17/08/2026"
      def date(value)
        return nil if value.blank?

        value.to_date.strftime("%d/%m/%Y")
      end

      # "17/08/2026 14:30"
      def datetime(value)
        return nil if value.blank?

        value.in_time_zone.strftime("%d/%m/%Y %H:%M")
      end

      # Normaliza una celda: blanco uniforme + escape de fórmulas.
      def cell(value)
        return nil if value.nil?

        text = value.to_s
        return nil if text.strip.empty?

        formula_risk?(text) ? "'#{text}" : text
      end

      private

      def formula_risk?(text)
        return true if FORMULA_PREFIXES.any? { |prefix| text.start_with?(prefix) }

        # "-1+cmd|..." es inyección; "-84500,00" es un número negativo legítimo.
        text.start_with?("-") && !text[1].to_s.match?(/\d/)
      end
    end

    # Envoltorio del CSV nativo: aplica #cell a cada valor para que ninguna
    # fila del sistema pueda saltearse la normalización.
    class Sink
      def initialize(csv)
        @csv = csv
      end

      def <<(row)
        @csv << Array(row).map { |value| CsvBuilder.cell(value) }
        self
      end
    end
  end
end
