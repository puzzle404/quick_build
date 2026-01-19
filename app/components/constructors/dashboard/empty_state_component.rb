# frozen_string_literal: true

module Constructors
  module Dashboard
    class EmptyStateComponent < ViewComponent::Base
      def initialize(
        title: "Todavía no tenés proyectos",
        description: "Creá tu primer proyecto para empezar a gestionar tus obras de manera profesional.",
        cta_text: "Crear mi primer proyecto",
        cta_path: nil
      )
        @title = title
        @description = description
        @cta_text = cta_text
        @cta_path = cta_path
      end

      def cta_path
        @cta_path || helpers.new_constructors_project_path
      end
    end
  end
end
