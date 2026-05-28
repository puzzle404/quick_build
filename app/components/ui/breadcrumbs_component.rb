# frozen_string_literal: true

module Ui
  class BreadcrumbsComponent < ViewComponent::Base
    # items: Array de hashes con claves:
    #   - :label (String) obligatorio
    #   - :path (String/Hash) opcional, si está se renderiza como enlace
    # class_name: String opcional para agregar clases extra al contenedor
    def initialize(items:, class_name: nil)
      @items = Array(items).compact
      @class_name = class_name
    end

    private

    attr_reader :items, :class_name

    def container_classes
      [
        "breadcrumbs text-sm",
        class_name
      ].compact.join(" ")
    end
  end
end

