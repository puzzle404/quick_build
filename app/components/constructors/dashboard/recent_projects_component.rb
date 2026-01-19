# frozen_string_literal: true

module Constructors
  module Dashboard
    class RecentProjectsComponent < ViewComponent::Base
      def initialize(projects:)
        @projects = projects
      end

      private

      attr_reader :projects

      def status_badge_class(status)
        case status.to_sym
        when :planned then 'bg-sky-100 text-sky-700'
        when :in_progress then 'bg-amber-100 text-amber-700'
        when :completed then 'bg-emerald-100 text-emerald-700'
        else 'bg-slate-100 text-slate-600'
        end
      end

      def status_label(status)
        case status.to_sym
        when :planned then 'Planificado'
        when :in_progress then 'En progreso'
        when :completed then 'Completado'
        else status.to_s.humanize
        end
      end
    end
  end
end
