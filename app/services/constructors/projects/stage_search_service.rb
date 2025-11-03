module Constructors
  module Projects
    class StageSearchService
      def initialize(project:, query: nil)
        @project = project
        @query = query.presence
      end

      def main_stages
        scope = base_scope.root.includes(:material_lists, :sub_stages).ordered
        return scope unless query

        scope.search_main_scope(query).ordered
      end

      def sub_stages
        scope = base_scope.children.includes(:parent, :material_lists).ordered
        return scope unless query

        scope.search_sub_scope(query).ordered
      end

      private

      attr_reader :project, :query

      def base_scope
        project.project_stages
      end
    end
  end
end
