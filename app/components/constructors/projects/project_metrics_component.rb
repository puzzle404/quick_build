# frozen_string_literal: true

module Constructors
  module Projects
    class ProjectMetricsComponent < ViewComponent::Base
      def initialize(project:)
        @project = project
      end

      private

      attr_reader :project

      def metrics
        [
          {
            title: "Duración estimada",
            value: project.duration_text,
            description: project.duration_hint
          },
          {
            title: "Miembros activos",
            value: project.total_members,
            suffix: "colaboradores",
            description: "Incluye administradores, editores y observadores."
          },
          {
            title: "Tiempo transcurrido",
            value: project.elapsed_days,
            suffix: project.time_elapsed_hint,
            description: "Se calcula al registrar la fecha de inicio."
          },
          {
            title: "Documentos adjuntos",
            value: project.attachments_count,
            suffix: "archivos",
            description: "Planos, fotos e información respaldatoria de la obra."
          }
        ]
      end
    end
  end
end
