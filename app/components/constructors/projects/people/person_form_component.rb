# frozen_string_literal: true

module Constructors
  module Projects
    module People
      # Form de persona agrupado en bloques: Identidad / Condiciones / Vigencia
      # / Notas. Lo comparten el alta y la edición, en sus dos ramas (drawer
      # global y página completa), así que los labels se mantienen estables.
      #
      # `in_drawer: true` hace que Cancelar cierre el drawer en vez de navegar
      # (las vistas de new/edit lo pasan en la rama turbo_frame).
      class PersonFormComponent < ViewComponent::Base
        STATUS_LABELS = { "active" => "Activa", "inactive" => "Licencia" }.freeze

        def initialize(project:, person:, in_drawer: false)
          @project = project
          @person = person
          @in_drawer = in_drawer
        end

        private

        attr_reader :project, :person

        def in_drawer?
          @in_drawer
        end

        def form_url
          if person.persisted?
            helpers.constructors_project_person_path(project, person)
          else
            helpers.constructors_project_people_path(project)
          end
        end

        def form_method
          person.persisted? ? :patch : :post
        end

        def submit_label
          person.persisted? ? "Guardar cambios" : "Crear persona"
        end

        def cancel_href
          if person.persisted?
            helpers.constructors_project_person_path(project, person)
          else
            helpers.constructors_project_people_path(project)
          end
        end

        def status_options
          ProjectPerson.statuses.keys.map { |k| [ STATUS_LABELS[k] || k.humanize, k ] }
        end

        # La tarifa se tipea en pesos (es-AR) y el controller la pasa a centavos
        # con Money::ArsParser. Se muestra sin separador de miles para que el
        # round-trip sea idempotente.
        def hourly_rate_pesos_value
          cents = person.hourly_rate_cents
          return nil if cents.blank?

          (cents % 100).zero? ? (cents / 100).to_s : format("%.2f", cents / 100.0).tr(".", ",")
        end
      end
    end
  end
end
