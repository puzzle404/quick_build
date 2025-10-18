# frozen_string_literal: true

module Constructors
  module Projects
    class PlanningPanelComponent < ViewComponent::Base
      include Constructors::ProjectsHelper

      def initialize(project:)
        @project = project
      end

      private

      attr_reader :project
    end
  end
end
