# frozen_string_literal: true

module Constructors
  module Projects
    module Stages
      class StageCardComponent < ViewComponent::Base
        def initialize(project:, stage:)
          @project = project
          @stage = stage
        end

        private

        attr_reader :project, :stage

        def period
          helpers.project_stage_period(stage)
        end

        def can_destroy?
          helpers.policy(stage).destroy?
        end

        def can_manage_materials?
          helpers.policy(project).manage_materials?
        end
      end
    end
  end
end

