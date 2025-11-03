# frozen_string_literal: true

module Constructors
  module Projects
    module Stages
      class StageFormComponent < ViewComponent::Base
        def initialize(project:, stage:)
          @project = project
          @stage = stage
        end

        private

        attr_reader :project, :stage

        def form_url
          if stage.persisted?
            helpers.constructors_project_stage_path(project, stage)
          else
            helpers.constructors_project_stages_path(project)
          end
        end

        def form_method
          stage.persisted? ? :patch : :post
        end

        def submit_label
          stage.persisted? ? "Actualizar etapa" : "Guardar etapa"
        end

        def parent_field_value
          stage.parent_id.presence || options_parent_id
        end

        def options_parent_id
          stage.parent&.id
        end
      end
    end
  end
end
