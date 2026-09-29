# frozen_string_literal: true

module Constructors
  module Projects
    class ProjectSearchService
      def initialize(scope:, query: nil, from_date: nil, to_date: nil)
        @scope = scope
        @query = query.to_s.strip.presence
        @from_date = from_date
        @to_date = to_date
      end

      def results
        search_scope = scope
        search_scope = apply_query(search_scope)
        search_scope = apply_date_filter(search_scope)

        search_scope.order(updated_at: :desc)
      end

      private

      attr_reader :scope, :query, :from_date, :to_date

      def apply_query(current_scope)
        return current_scope unless query

        current_scope.merge(Project.search_text(query))
      end

      def apply_date_filter(current_scope)
        Support::DateRangeFilter.apply(
          scope: current_scope,
          columns: %w[start_date end_date updated_at],
          from: from_date,
          to: to_date
        )
      end
    end
  end
end
