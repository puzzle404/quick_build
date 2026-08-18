# frozen_string_literal: true

module Support
  class DateRangeFilter
    def self.apply(scope:, columns:, from: nil, to: nil)
      new(scope: scope, columns: columns, from: from, to: to).apply
    end

    def initialize(scope:, columns:, from: nil, to: nil)
      @scope = scope
      @columns = Array(columns).reject(&:blank?)
      @from = from
      @to = to
    end

    def apply
      return scope unless columns.present? && (from.present? || to.present?)

      from_value, to_value = normalized_bounds

      # If normalization fails (e.g., both nil after parsing), return original scope
      return scope unless from_value.present? || to_value.present?

      condition_sql, params = build_condition(from_value, to_value)

      scope.where([condition_sql, params])
    end

    private

    attr_reader :scope, :columns, :from, :to

    def build_condition(from_value, to_value)
      quoted_columns = columns.map { |column| quote_column(column) }
      date_columns = quoted_columns.map { |column| "DATE(#{column})" }

      if from_value.present? && to_value.present?
        sql = date_columns.map do |column|
          "(#{column} IS NOT NULL AND #{column} BETWEEN :from AND :to)"
        end.join(' OR ')
        ["(#{sql})", { from: from_value, to: to_value }]
      elsif from_value.present?
        sql = date_columns.map do |column|
          "(#{column} IS NOT NULL AND #{column} >= :from)"
        end.join(' OR ')
        ["(#{sql})", { from: from_value }]
      else
        sql = date_columns.map do |column|
          "(#{column} IS NOT NULL AND #{column} <= :to)"
        end.join(' OR ')
        ["(#{sql})", { to: to_value }]
      end
    end

    def normalized_bounds
      parsed_from = parse_date(from)
      parsed_to = parse_date(to)

      if parsed_from.present? && parsed_to.present? && parsed_from > parsed_to
        parsed_from, parsed_to = parsed_to, parsed_from
      end

      [parsed_from, parsed_to]
    end

    def parse_date(value)
      return if value.blank?

      parsed = value.is_a?(Date) || value.is_a?(Time) ? value.to_date : Date.parse(value.to_s)
      parsed
    rescue ArgumentError
      nil
    end

    def quote_column(column)
      case column
      when Arel::Attributes::Attribute
        relation_name = column.relation&.name
        parts = [relation_name, column.name].compact
        parts.map { |part| scope.connection.quote_column_name(part) }.join('.')
      when String
        if column.include?('.')
          column.split('.').map { |part| scope.connection.quote_column_name(part) }.join('.')
        else
          scope.connection.quote_column_name(column)
        end
      when Symbol
        scope.connection.quote_column_name(column)
      else
        scope.connection.quote_column_name(column.to_s)
      end
    end
  end
end
