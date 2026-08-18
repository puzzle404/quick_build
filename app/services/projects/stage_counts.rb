# frozen_string_literal: true

module Projects
  # Conteos de adjuntos por etapa —documentos, fotos y listas de materiales—
  # resueltos en TRES queries agrupadas para todo el set de etapas.
  #
  # Mismo patrón que Projects::SpendSummary#by_stage: el controller lo arma una
  # vez y lo inyecta en las cards, así el workspace de etapas deja de pedir tres
  # `.count` por tarjeta y otros tres por sub-etapa (era el N+1 más caro de
  # projects#show).
  #
  #   counts = Projects::StageCounts.for_project(project)
  #   counts.docs(stage.id)            # => 3
  #   counts.images(stage.id)          # => 0
  #   counts.material_lists(stage.id)  # => 1
  #
  # Las queries son perezosas: si nadie pregunta por fotos, no se consulta
  # `images`. Con un set vacío de etapas no toca la base.
  class StageCounts
    # Todas las etapas de la obra (raíces y sub-etapas) en un solo objeto.
    def self.for_project(project)
      project_id = project.respond_to?(:id) ? project.id : project
      new(ProjectStage.where(project_id: project_id).select(:id))
    end

    # Acotado a un set conocido de etapas: lo usa la card cuando se renderiza
    # suelta (el turbo_stream de stages#create) y nadie le inyectó nada.
    def self.for_stage_ids(stage_ids)
      new(Array(stage_ids).compact.uniq)
    end

    # +stage_ids+ acepta un array de ids o una relación de ProjectStage para
    # que la subquery viaje como SQL en vez de traer los ids a Ruby.
    def initialize(stage_ids)
      @stage_ids = stage_ids
    end

    def docs(stage_id)
      docs_by_stage[stage_id].to_i
    end

    def images(stage_id)
      images_by_stage[stage_id].to_i
    end

    def material_lists(stage_id)
      material_lists_by_stage[stage_id].to_i
    end

    private

    def docs_by_stage
      @docs_by_stage ||= grouped(
        Document.where(documentable_type: "ProjectStage", documentable_id: @stage_ids),
        :documentable_id
      )
    end

    def images_by_stage
      @images_by_stage ||= grouped(
        Image.where(imageable_type: "ProjectStage", imageable_id: @stage_ids),
        :imageable_id
      )
    end

    def material_lists_by_stage
      @material_lists_by_stage ||= grouped(
        MaterialList.where(project_stage_id: @stage_ids),
        :project_stage_id
      )
    end

    def grouped(scope, column)
      return {} if empty_scope?

      scope.group(column).count
    end

    # Un array vacío generaría un `IN (NULL)` inútil; una relación no se
    # materializa acá a propósito (viaja como subquery).
    def empty_scope?
      @stage_ids.is_a?(Array) && @stage_ids.empty?
    end
  end
end
