# frozen_string_literal: true

module Constructors
  module Projects
    module People
      # Una fila de la tabla de asistencias de la ficha de persona.
      #
      # Es la única celda editable de la ficha: las horas se cargan DESPUÉS de
      # la marca, sobre la marca que ya existe. Un form por fila y un botón
      # explícito — nada de guardar al perder el foco: en obra se carga desde
      # el teléfono y un blur-submit invisible es imposible de confirmar.
      #
      # La respuesta del PATCH reemplaza esta misma fila (+ el total del pie)
      # por turbo_stream, así cargar diez jornadas no recarga diez veces la
      # página ni pierde el scroll.
      class AttendanceRowComponent < ViewComponent::Base
        include HoursFormat

        DAY_NAMES = %w[dom lun mar mié jue vie sáb].freeze
        SOURCE_LABELS = { "manual" => "Manual", "qr" => "QR", "mobile" => "Móvil" }.freeze

        def self.row_id(attendance)
          "attendance_row_#{attendance.id}"
        end

        def initialize(attendance:, project:)
          @attendance = attendance
          @project = project
        end

        private

        attr_reader :attendance, :project

        def row_id
          self.class.row_id(attendance)
        end

        # Quién puede completar/limpiar las horas lo decide la policy (editor+
        # según la matriz), no un chequeo de rol escrito acá.
        def editable?
          return @editable if defined?(@editable)

          @editable = helpers.policy(attendance).update?
        end

        def deletable?
          return @deletable if defined?(@deletable)

          @deletable = helpers.policy(attendance).destroy?
        end

        def day_label
          DAY_NAMES[attendance.occurred_at.to_date.wday]
        end

        def source_label
          SOURCE_LABELS[attendance.source] || attendance.source.to_s.humanize.presence || "Manual"
        end

        def hours_label
          fmt_hours_label(attendance.hours)
        end

        def hours_errors
          attendance.errors[:hours]
        end

        # Con error mostramos lo que se tipeó (para poder corregirlo, no para
        # adivinar qué se escribió); sin error, el valor guardado en es-AR.
        def input_value
          return attendance.hours_before_type_cast.to_s if hours_errors.any?

          fmt_hours(attendance.hours)
        end

        def update_path
          helpers.constructors_project_person_attendance_path(project, attendance.project_person_id, attendance)
        end

        def field_label
          "Horas trabajadas del #{helpers.qb_fmt_date_short(attendance.occurred_at.to_date)}"
        end
      end
    end
  end
end
