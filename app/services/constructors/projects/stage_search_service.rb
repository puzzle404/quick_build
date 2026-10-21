module Constructors
  module Projects
    class StageSearchService
      def initialize(project:, query: nil, from_date: nil, to_date: nil)
        @project = project
        @query = query.presence
        @from_date = from_date
        @to_date = to_date
      end

      def main_stages
        scope = base_scope.root.includes(:material_lists, :sub_stages)
        scope = apply_date_filter(scope)
        scope = scope.search_main_scope(query) if query

        scope.ordered
      end

      def sub_stages
        scope = base_scope.children.includes(:parent, :material_lists)
        scope = apply_date_filter(scope)
        scope = scope.search_sub_scope(query) if query

        scope.ordered
      end

      private

      attr_reader :project, :query, :from_date, :to_date

      def base_scope
        project.project_stages
      end

      def apply_date_filter(scope)
        Support::DateRangeFilter.apply(
          scope: scope,
          columns: %w[start_date end_date],
          from: from_date,
          to: to_date
        )
      end
    end
  end
end
