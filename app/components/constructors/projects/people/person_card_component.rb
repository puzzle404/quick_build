# frozen_string_literal: true

module Constructors
  module Projects
    module People
      class PersonCardComponent < ViewComponent::Base
        def initialize(project:, person:)
          @project = project
          @person = person
        end

        private

        attr_reader :project, :person
      end
    end
  end
end

