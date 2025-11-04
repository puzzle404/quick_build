# frozen_string_literal: true

module Constructors
  module Projects
    class PeopleSearchService
      def initialize(project:, query: nil, from_date: nil, to_date: nil)
        @project = project
        @query = query.to_s.strip.presence
        @from_date = from_date
        @to_date = to_date
      end

      def results
        scope = project.project_people
        scope = apply_query(scope)
        scope = apply_date_filter(scope)
        scope.order(created_at: :desc)
      end

      private

      attr_reader :project, :query, :from_date, :to_date

      def apply_query(scope)
        return scope unless query

        scope.merge(ProjectPerson.search_text(query))
      end

      def apply_date_filter(scope)
        Support::DateRangeFilter.apply(
          scope: scope,
          columns: %w[project_people.start_date project_people.end_date project_people.created_at],
          from: from_date,
          to: to_date
        )
      end
    end
  end
end
