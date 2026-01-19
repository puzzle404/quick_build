# frozen_string_literal: true

module Constructors
  module Dashboard
    class QuickActionsComponent < ViewComponent::Base
      def initialize(user:)
        @user = user
      end

      def render?
        false
      end
      
      def recent_material_lists
        @user.owned_projects
             .joins(:material_lists)
             .includes(material_lists: :project)
             .flat_map(&:material_lists)
             .sort_by(&:updated_at)
             .reverse
             .first(3)
      end

      def recent_blueprints
        @user.owned_projects
             .joins(:blueprints)
             .includes(blueprints: :project)
             .flat_map(&:blueprints)
             .sort_by(&:updated_at)
             .reverse
             .first(3)
      end

      def has_content?
        @user.owned_projects.any?
      end
    end
  end
end
