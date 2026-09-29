# frozen_string_literal: true

module Constructors
  module Projects
    module People
      # "Otras obras de esta persona" — la misma persona física suele estar
      # asignada a varias obras (7 de 14 personas de la base están en 6), y hasta
      # ahora eso sólo se veía entrando a la ficha global. Este bloque es lo que
      # le da sentido al botón "Ficha global" desde la ficha por obra.
      #
      # La identidad se agrupa por (nombre, teléfono), igual que
      # Constructors::PeopleController#siblings_of: sin teléfono la clave no
      # distingue homónimos, así que no agrupamos.
      class OtherProjectsComponent < ViewComponent::Base
        def initialize(person:, project:)
          @person = person
          @project = project
        end

        def render?
          others.any?
        end

        private

        attr_reader :person, :project

        def others
          @others ||= begin
            if person.phone.blank?
              []
            else
              ProjectPerson.joins(:project)
                           .where(projects: { owner_id: project.owner_id })
                           .where(full_name: person.full_name, phone: person.phone)
                           .where.not(id: person.id)
                           .includes(:project)
                           .sort_by { |a| a.project.name.to_s }
            end
          end
        end

        def active?(assignment)
          assignment.status.to_s == "active"
        end

        def person_href(assignment)
          helpers.constructors_project_person_path(assignment.project, assignment)
        end
      end
    end
  end
end
