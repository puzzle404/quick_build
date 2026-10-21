# frozen_string_literal: true

module Constructors
  module Projects
    module People
      # Formateo de horas trabajadas en es-AR, compartido por la fila y el
      # total de la tabla de asistencias (y por el KPI de la ficha).
      #
      # No vive en QuickbuildHelper porque las horas no son plata: no pasan
      # por qb_fmt_cents ni llevan símbolo. Reglas: coma decimal, sin
      # decimales cuando la jornada es entera (8, no 8,00).
      module HoursFormat
        module_function

        # 8.0 → "8" · 7.5 → "7,5" · 7.25 → "7,25" · nil → nil
        def fmt_hours(value)
          return nil if value.blank?

          number = value.to_d
          return number.to_i.to_s if number == number.truncate

          # Kernel.format explícito: ViewComponent::Base define su propio
          # #format (el formato de render, sin argumentos) y al incluir este
          # módulo el `format("%.2f", n)` pelado se resolvía contra ése.
          Kernel.format("%.2f", number).sub(/0\z/, "").tr(".", ",")
        end

        # "8 hs" / "1 h" — la unidad va pegada al número en la UI.
        def fmt_hours_label(value)
          text = fmt_hours(value)
          return nil if text.nil?

          "#{text} #{value.to_d == 1 ? 'h' : 'hs'}"
        end
      end
    end
  end
end
