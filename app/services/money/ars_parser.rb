# frozen_string_literal: true

module Money
  # Convierte importes tipeados por el usuario (es-AR) a centavos.
  #
  # Los forms de la app aceptan texto libre con inputmode="decimal", así que
  # llegan cosas como "1.500,50", "$ 1500", "1500.50" o "1 500". Un
  # `gsub(/[^\d]/, '')` naive convertía "1.500,50" en 150050 pesos → 100× de más.
  #
  # Convención es-AR: "," es decimal y "." es separador de miles. Cuando sólo
  # aparece ".", se desambigua por la cantidad de dígitos que le siguen: 3 →
  # miles ("1.500"), cualquier otra cosa → decimal ("1500.50").
  module ArsParser
    module_function

    # @return [Integer, nil] centavos, o nil si no hay un número parseable
    def to_cents(input)
      return nil if input.nil?
      return input if input.is_a?(Integer)

      raw = input.to_s.strip
      return nil if raw.empty?

      cleaned = raw.gsub(/[^\d.,-]/, "")
      return nil if cleaned.empty? || cleaned.match?(/\A-?[.,]*\z/)

      negative = cleaned.start_with?("-")
      cleaned = cleaned.delete("-")

      normalized = normalize(cleaned)
      return nil if normalized.blank?

      cents = (BigDecimal(normalized) * 100).round
      negative ? -cents : cents
    rescue ArgumentError, TypeError
      nil
    end

    # Normaliza a una representación con "." decimal y sin separadores de miles.
    def normalize(cleaned)
      if cleaned.include?(",")
        # Con coma presente, la coma manda como decimal (es-AR).
        cleaned.delete(".").sub(",", ".")
      elsif cleaned.include?(".")
        decimals = cleaned.split(".").last
        if cleaned.count(".") > 1 || decimals.length == 3
          cleaned.delete(".") # miles: "1.500" o "1.500.000"
        else
          cleaned # decimal: "1500.50"
        end
      else
        cleaned
      end
    end
    private_class_method :normalize
  end
end
