# frozen_string_literal: true

module Constructors
  module Dashboard
    class UpcomingStagesPanelComponent < ViewComponent::Base
      def initialize(stages: [])
        @stages = stages
      end

      private

      attr_reader :stages
    end
  end
end

