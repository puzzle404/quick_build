# frozen_string_literal: true

module Constructors
  module Projects
    module MaterialLists
      class CardComponent < ViewComponent::Base
        def initialize(project:, material_list:)
          @project = project
          @material_list = material_list
        end

        private

        attr_reader :project, :material_list

        def publication
          material_list.material_list_publication
        end
      end
    end
  end
end

