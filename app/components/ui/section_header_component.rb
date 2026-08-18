# frozen_string_literal: true

module Ui
  class SectionHeaderComponent < ViewComponent::Base
    # Params
    # - title: String (required)
    # - subtitle: String (optional)
    # - meta_html: String (optional HTML rendered below subtitle)
    # - class_name: String (optional extra classes on container)
    def initialize(title:, subtitle: nil, meta_html: nil, class_name: nil)
      @title = title
      @subtitle = subtitle
      @meta_html = meta_html
      @class_name = class_name
    end

    private

    attr_reader :title, :subtitle, :meta_html, :class_name

    def container_classes
      [
        "mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between",
        class_name
      ].compact.join(" ")
    end
  end
end

