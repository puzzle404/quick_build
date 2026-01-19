# frozen_string_literal: true

module Constructors
  module Projects
    module Stages
      class StageHeaderComponent < ViewComponent::Base
        def initialize(project:, stage:)
          @project = project
          @stage = stage
        end

        private

        attr_reader :project, :stage

        def breadcrumb_items
          items = []
          items << { label: "Planificación", path: helpers.constructors_project_stages_path(project) }
          if stage.parent.present?
            items << { label: stage.parent.name, path: helpers.constructors_project_stage_path(project, stage.parent) }
          end
          items
        end

        def status_badge
          return unless stage.start_date || stage.end_date

          dates = []
          dates << helpers.l(stage.start_date, format: :long) if stage.start_date
          dates << helpers.l(stage.end_date, format: :long) if stage.end_date
          dates.join(" · ")
        end

        def edit_path
          helpers.edit_constructors_project_stage_path(project, stage) if helpers.policy(stage).update?
        end

        def parent_path
          helpers.constructors_project_stage_path(project, stage.parent) if stage.parent
        end
      end
    end
  end
end
