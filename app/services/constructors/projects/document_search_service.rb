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
        return scope if from_date.blank? && to_date.blank?

        # The filter references active_storage_blobs.created_at; force the
        # LEFT OUTER JOIN so the column resolves. `includes` would only
        # JOIN if the where touched the joined columns, but the helper
        # builds raw SQL strings so AR can't see the dependency.
        scope_with_blobs = scope.left_outer_joins(file_attachment: :blob)
        Support::DateRangeFilter.apply(
          scope: scope_with_blobs,
          columns: %w[documents.created_at active_storage_blobs.created_at],
          from: from_date,
          to: to_date
        )
      end
    end
  end
end
