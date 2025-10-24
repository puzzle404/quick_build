# frozen_string_literal: true

module Constructors
  module Projects
    module MaterialLists
      class ItemFormComponent < ViewComponent::Base
        def initialize(project:, material_list:, material_item:)
          @project = project
          @material_list = material_list
          @material_item = material_item
        end

        private

        attr_reader :project, :material_list, :material_item
      end
    end
  end
end

