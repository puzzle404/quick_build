# frozen_string_literal: true

# Grouped form card (iOS settings-style). Children should be
# `Qb::Mobile::FormRow`, `Qb::Mobile::FormPickerRow`, `Qb::Mobile::FormToggleRow`,
# or `Qb::Mobile::FormAmountRow`. Last child's bottom divider is hidden via CSS
# (`.m-fg-body > *:last-child`).
class Qb::Mobile::FormGroupComponent < ViewComponent::Base
  def initialize(title: nil, footnote: nil)
    @title = title
    @footnote = footnote
  end
end
