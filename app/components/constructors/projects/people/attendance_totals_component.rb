# frozen_string_literal: true

module Constructors
  module Projects
    module People
      # Pie de la tabla de asistencias: total de horas de las marcas listadas
      # y, si la persona tiene tarifa, cuánto cuestan.
      #
      # Suma SOLO las marcas que se ven arriba (las últimas RECENT_LIMIT), no
      # una ventana distinta: un total que no cierra con las filas visibles es
      # peor que no mostrar total.
      #
      # El costo es tarifa × horas y se muestra sólo cuando existen los dos
      # datos. Sin tarifa (o sin horas) va un guion con el motivo al lado: un
      # número parcial disfrazado de total es peor que un guion.
      class AttendanceTotalsComponent < ViewComponent::Base
        include HoursFormat

        DOM_ID = "attendance_hours_total"

        def initialize(attendances:, person:, project:)
          @attendances = attendances
          @person = person
          @project = project
        end

        private

        attr_reader :attendances, :person, :project

        def dom_id
          DOM_ID
        end

        def with_hours_count
          @with_hours_count ||= attendances.count { |a| a.hours.present? }
        end

        def total_hours
          @total_hours ||= attendances.filter_map(&:hours).sum
        end

        def total_hours_label
          fmt_hours_label(total_hours) if total_hours.positive?
        end

        def rate_cents
          person.hourly_rate_cents
        end

        def total_cost_cents
          return nil if rate_cents.blank? || !total_hours.positive?

          (total_hours.to_d * rate_cents.to_i).round
        end

        def cost_label
          helpers.qb_fmt_cents(total_cost_cents) if total_cost_cents
        end

        # Por qué el costo es un guion, en criollo y con el link para
        # arreglarlo cuando lo que falta es la tarifa.
        def cost_hint
          return "cargá las horas de cada jornada" unless total_hours.positive?
          return "falta la tarifa por hora" if rate_cents.blank?
          return nil if with_hours_count == attendances.size

          "sobre #{with_hours_count} de #{attendances.size} marcas con horas"
        end

        def missing_rate?
          total_hours.positive? && rate_cents.blank?
        end

        def edit_href
          helpers.edit_constructors_project_person_path(project, person)
        end
      end
    end
  end
end
