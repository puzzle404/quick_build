# frozen_string_literal: true

module Constructors
  module Projects
    module People
      # Form de persona agrupado en bloques: Identidad / Condiciones / Vigencia
      # / Notas. Lo comparten el alta (modal «Invitar persona» + página) y la
      # edición, así que los labels se mantienen estables.
      class PersonFormComponent < ViewComponent::Base
        STATUS_LABELS = { "active" => "Activa", "inactive" => "Licencia" }.freeze

        def initialize(project:, person:)
          @project = project
          @person = person
        end

        private

        attr_reader :project, :person

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
