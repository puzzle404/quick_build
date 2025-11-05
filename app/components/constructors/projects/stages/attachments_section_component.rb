# frozen_string_literal: true

module Constructors
  module Projects
    module Stages
      class AttachmentsSectionComponent < ViewComponent::Base
        def initialize(project:, stage:, kind:)
          @project = project
          @stage = stage
          @kind = kind.to_sym
        end

        private

        attr_reader :project, :stage, :kind

        def title
          kind == :documents ? "Documentos" : "Imágenes"
        end

        def description
          kind == :documents ? "Planos, contratos u otros archivos en PDF." : "Fotografías o recursos visuales vinculados a la etapa."
        end

        def attachments
          @attachments ||= if kind == :documents
                              stage.documents.order(created_at: :desc)
                            else
                              stage.images.includes(file_attachment: :blob).order(created_at: :desc)
                            end
        end

        def empty_text
          kind == :documents ? "Todavía no se cargaron documentos." : "Todavía no se cargaron imágenes."
        end

        def upload_path
          if kind == :documents
            helpers.new_constructors_project_stage_document_path(project, stage)
          else
            helpers.new_constructors_project_stage_image_path(project, stage)
          end
        end

        def can_manage?
          helpers.policy(stage).update?
        end
      end
    end
  end
end
