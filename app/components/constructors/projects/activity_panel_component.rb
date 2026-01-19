# frozen_string_literal: true

module Constructors
  module Projects
    class ActivityPanelComponent < ViewComponent::Base
      def initialize(activity_entries:)
        @activity_entries = activity_entries
      end

      private

      attr_reader :activity_entries
    end
  end
end
