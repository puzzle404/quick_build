# frozen_string_literal: true

module Projects
  # Los seis contadores de las pestañas de la obra (etapas, materiales, gastos,
  # planos, equipo y documentos) en UNA query.
  #
  # `_section_tabs` se renderiza en TODAS las pantallas del proyecto, así que
  # cada `.count` suelto se pagaba seis veces por request en toda la sección.
  # Acá van como subqueries escalares de un mismo SELECT: el resultado es
  # idéntico al de los `.count` que reemplaza, con una sola ida a la base.
  #
  #   counts = Projects::SectionCounts.new(project)
  #   counts[:stages]   # => 9   (sólo etapas raíz, como la pantalla de Etapas)
  #   counts[:docs]     # => 4
  class SectionCounts
    # El orden fija el de las columnas del SELECT; las claves son las que
    # consume la vista.
    SCOPES = {
      stages: ->(id) { ProjectStage.where(project_id: id, parent_id: nil) },
      materials: ->(id) { MaterialList.where(project_id: id) },
      expenses: ->(id) { Expense.where(project_id: id) },
      blueprints: ->(id) { Blueprint.where(project_id: id) },
      team: ->(id) { ProjectPerson.where(project_id: id) },
      docs: ->(id) { Document.where(documentable_type: "Project", documentable_id: id) }
    }.freeze

    def initialize(project)
      @project_id = project.respond_to?(:id) ? project.id : project
    end

    def [](key)
      row[key.to_s].to_i
    end

    SCOPES.each_key do |key|
      define_method(key) { self[key] }
    end

    def to_h
      SCOPES.keys.index_with { |key| self[key] }
    end

    private

    def row
      return @row if defined?(@row)

      @row = @project_id.blank? ? {} : (ActiveRecord::Base.connection.select_one(sql) || {})
    end

    # Cada subquery la construye ActiveRecord (con el id ya escapado), así que
    # acá no se interpola nada a mano.
    def sql
      selects = SCOPES.map do |key, scope|
        "(#{scope.call(@project_id).select('COUNT(*)').to_sql}) AS #{key}"
      end

      "SELECT #{selects.join(', ')}"
    end
  end
end
