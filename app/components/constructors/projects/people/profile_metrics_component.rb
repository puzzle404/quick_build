# frozen_string_literal: true

module Constructors
  module Projects
    module People
      # KPI strip de la ficha de persona por obra.
      #
      # Sólo mide cosas que existen en la base: días con marca de asistencia,
      # días hábiles de la ventana, antigüedad desde start_date, tarifa y —
      # desde que las horas se pueden cargar sobre cada marca— el costo de
      # mano de obra de la persona en la ventana (tarifa × horas).
      #
      # Ese costo es guion cuando falta cualquiera de los dos factores: una
      # persona con horas pero sin tarifa (o al revés) no cuesta $0, cuesta
      # "todavía no se sabe".
      #
      # Los cálculos vivían inline en la vista (2 queries en el ERB); acá quedan
      # en un solo lugar y con una sola query.
      class ProfileMetricsComponent < ViewComponent::Base
        include HoursFormat

        WINDOW_DAYS = 30

        def initialize(person:, project:)
          @person = person
          @project = project
        end

        private

        attr_reader :person, :project

        def window_days
          WINDOW_DAYS
        end

        # Una sola query: todas las marcas desde el inicio de la ventana más
        # larga (30 días vs. inicio de mes), con sus horas, recortadas en
        # memoria. Traer `hours` acá evita una segunda query para el costo.
        def stamps
          @stamps ||= begin
            lower = [ WINDOW_DAYS.days.ago.beginning_of_day, Date.current.beginning_of_month.to_time ].min
            person.person_attendances
                  .where(occurred_at: lower..Time.current.end_of_day)
                  .pluck(:occurred_at, :hours)
          end
        end

        def days_in(range)
          stamps.select { |at, _h| range.cover?(at) }.map { |at, _h| at.to_date }.uniq.size
        end

        def window_range
          @window_range ||= WINDOW_DAYS.days.ago.beginning_of_day..Time.current.end_of_day
        end

        def window_stamps
          @window_stamps ||= stamps.select { |at, _h| window_range.cover?(at) }
        end

        def window_stamps_with_hours
          @window_stamps_with_hours ||= window_stamps.select { |_at, h| h.present? }
        end

        # 0 cuando no hay ninguna hora cargada — el KPI lo traduce a guion, no
        # a "0 hs" (que se leería como "no trabajó").
        def window_hours
          @window_hours ||= window_stamps_with_hours.sum { |_at, h| h }
        end

        def window_days_marked
          @window_days_marked ||= days_in(WINDOW_DAYS.days.ago.beginning_of_day..Time.current.end_of_day)
        end

        def month_days_marked
          @month_days_marked ||= days_in(Date.current.beginning_of_month.to_time..Time.current.end_of_day)
        end

        def business_days
          @business_days ||= (WINDOW_DAYS.days.ago.to_date..Date.current).count { |d| ![ 0, 6 ].include?(d.wday) }
        end

        def attendance_pct
          return nil unless business_days.positive?
          (window_days_marked.to_f / business_days * 100).round
        end

        def attendance_tone
          pct = attendance_pct
          return nil if pct.nil?
          return :ok if pct >= 85
          pct >= 70 ? :warn : nil
        end

        def seniority_days
          return nil if person.start_date.blank?
          last = [ person.end_date, Date.current ].compact.min
          [ (last - person.start_date).to_i, 0 ].max
        end

        def seniority_value
          d = seniority_days
          return "—" if d.nil?
          return "#{d} #{d == 1 ? 'día' : 'días'}" if d < 60

          months = (d / 30.0).round
          "#{months} meses"
        end

        def vigencia
          return "sin fechas cargadas" if person.start_date.blank?
          if person.end_date.present?
            "#{helpers.qb_fmt_date_short(person.start_date)} → #{helpers.qb_fmt_date_short(person.end_date)}"
          else
            "desde #{helpers.qb_fmt_date_short(person.start_date)}"
          end
        end

        def rate_cents
          person.hourly_rate_cents
        end

        # Costo de mano de obra de ESTA persona en la ventana: tarifa × horas.
        # nil si falta cualquiera de los dos — mostrar un número con la mitad
        # de los datos es peor que mostrar un guion.
        def labor_cost_cents
          return nil if rate_cents.blank? || !window_hours.positive?

          (window_hours.to_d * rate_cents.to_i).round
        end

        # El hint dice qué falta cuando el valor es guion, y avisa cuando el
        # costo es parcial (hay marcas de la ventana sin horas cargadas).
        def labor_cost_hint
          return "sin horas cargadas en las marcas" unless window_hours.positive?
          return "falta la tarifa por hora" if rate_cents.blank?

          hours = fmt_hours_label(window_hours)
          if window_stamps_with_hours.size < window_stamps.size
            "#{hours} · #{window_stamps_with_hours.size} de #{window_stamps.size} marcas"
          else
            "#{hours} en #{WINDOW_DAYS} días"
          end
        end

        def labor_cost_missing_rate?
          window_hours.positive? && rate_cents.blank?
        end

        def edit_href
          helpers.edit_constructors_project_person_path(project, person)
        end
      end
    end
  end
end
