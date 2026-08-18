# frozen_string_literal: true

# iOS-style nav bar (back chevron · centred title · right slot).
# Hotwire Native iOS provides its own UINavigationController; this is the
# in-page fallback used in plain-browser previews and on screens that need
# an inline title (e.g. modals presented as bottom sheets).
class Qb::Mobile::NavBarComponent < ViewComponent::Base
  renders_one :right

  def initialize(title: nil, back: true, back_href: nil)
    @title = title
    @back = back
    @back_href = back_href
  end
end
