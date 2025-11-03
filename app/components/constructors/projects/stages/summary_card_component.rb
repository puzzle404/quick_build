# frozen_string_literal: true

module Constructors
  module Projects
    module Stages
      class SummaryCardComponent < ViewComponent::Base
        def initialize(project:, stage:)
          @project = project
          @stage = stage
        end

        private

        attr_reader :project, :stage

        def period
          helpers.project_stage_period(stage)
        end

        def sub_stage_count
          stage.sub_stages.count
        end

        def material_list_count
          stage.material_lists.count
        end

        def status_label
          if stage.start_date.present? && stage.end_date.present?
            "#{helpers.l(stage.start_date, format: :short)} · #{helpers.l(stage.end_date, format: :short)}"
          elsif stage.start_date.present?
            "Desde #{helpers.l(stage.start_date, format: :short)}"
          else
            "Sin fechas cargadas"
          end
        end

        def show_path
          helpers.constructors_project_stage_path(project, stage)
        end

        def edit_path
          helpers.edit_constructors_project_stage_path(project, stage)
        end
      end
    end
  end
end
