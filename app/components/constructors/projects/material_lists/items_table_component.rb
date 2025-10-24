# frozen_string_literal: true

module Constructors
  module Projects
    module MaterialLists
      class ItemsTableComponent < ViewComponent::Base
        def initialize(project:, material_list:, material_items:, editable: false)
          @project = project
          @material_list = material_list
          @material_items = material_items
          @editable = editable
        end

        private

        attr_reader :project, :material_list, :material_items

        def editable?
          @editable
        end
      end
    end
  end
end

