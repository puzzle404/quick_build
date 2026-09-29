# frozen_string_literal: true

module Ui
  class MediaCardComponent < ViewComponent::Base
    def initialize(title:, description:, image_url:, href: "#", image_alt: nil)
      @title = title
      @description = description
      @image_url = image_url
      @href = href
      @image_alt = image_alt.presence || title
    end

    private

    attr_reader :title, :description, :image_url, :href, :image_alt
  end
end

