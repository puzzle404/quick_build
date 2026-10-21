# frozen_string_literal: true

# Cuenta las queries reales de un bloque, para specs de N+1.
module QueryCounter
  IGNORED_QUERY_NAMES = %w[SCHEMA TRANSACTION].freeze

  def capture_queries
    queries = []

    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if payload[:cached] || IGNORED_QUERY_NAMES.include?(payload[:name])

      queries << payload[:sql]
    end

    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def count_queries(&block)
    capture_queries(&block).size
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
