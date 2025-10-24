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
      end
    end
  end
end

