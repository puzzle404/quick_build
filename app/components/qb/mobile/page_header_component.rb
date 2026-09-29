# frozen_string_literal: true

# Large title iOS page header. `dense: true` halves the bottom padding and
# drops the title to 24px (used on inner screens with sticky nav above).
class Qb::Mobile::PageHeaderComponent < ViewComponent::Base
  renders_one :action

  def initialize(title:, eyebrow: nil, subtitle: nil, dense: false)
    @title = title
    @eyebrow = eyebrow
    @subtitle = subtitle
    @dense = dense
  end
end
