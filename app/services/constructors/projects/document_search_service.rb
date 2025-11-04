# frozen_string_literal: true

module Constructors
  module Projects
    class DocumentSearchService
      def initialize(project:, query: nil, from_date: nil, to_date: nil)
        @project = project
        @query = query.to_s.strip.presence
        @from_date = from_date
        @to_date = to_date
      end

      def results
        scope = base_scope
        scope = apply_query(scope)
        scope = apply_date_filter(scope)
        scope.order(documents: { created_at: :desc })
      end

      private

      attr_reader :project, :query, :from_date, :to_date

      def base_scope
        project.documents.includes(file_attachment: :blob)
      end

      def apply_query(scope)
        return scope unless query

        scope.merge(Document.search_text(query))
      end

      def apply_date_filter(scope)
        Support::DateRangeFilter.apply(
          scope: scope,
          columns: %w[documents.created_at active_storage_blobs.created_at],
          from: from_date,
          to: to_date
        )
      end
    end
  end
end
