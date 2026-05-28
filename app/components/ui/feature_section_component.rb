# frozen_string_literal: true

class Ui::FeatureSectionComponent < ViewComponent::Base
  def initialize(title:, description:, image_url:, image_alt: "", reversed: false)
    @title = title
    @description = description
    @image_url = image_url
    @image_alt = image_alt
    @reversed = reversed
  end
end
