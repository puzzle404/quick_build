# frozen_string_literal: true

module Constructors
  module Projects
    module Stages
      class SubstageTableComponent < ViewComponent::Base
        def initialize(project:, stage:, substages:)
          @project = project
          @stage = stage
          @substages = substages
        end

        private

        attr_reader :project, :stage, :substages

        def can_manage?
          helpers.policy(stage).update?
        end

        def new_substage_path
          helpers.new_constructors_project_stage_path(project, parent_id: stage.id)
        end

        def row_path(substage)
          helpers.constructors_project_stage_path(project, substage)
        end

        def edit_path(substage)
          helpers.edit_constructors_project_stage_path(project, substage)
        end

        def destroy_path(substage)
          helpers.constructors_project_stage_path(project, substage)
        end
      end
    end
  end
end
