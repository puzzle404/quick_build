# frozen_string_literal: true

require "view_component/test_helpers"
require "capybara/rspec"
require "rails_helper"

RSpec.describe Ui::ButtonComponent, type: :component do
  include ViewComponent::TestHelpers
  include Capybara::RSpecMatchers

  it "renders a link when no method is provided" do
    render_inline(described_class.new(label: "Go", path: "/projects"))

    expect(rendered_content).to have_css("a[href='/projects']", text: "Go")
  end

  it "renders a form button when a non-get method is provided" do
    render_inline(
      described_class.new(
        label: "Remove",
        path: "/projects/1",
        method: :delete,
        data: { turbo_confirm: "Sure?" },
        variant: :danger
      )
    )

    expect(rendered_content).to have_css("form[action='/projects/1'][method='post']")
    expect(rendered_content).to have_css("button", text: "Remove")
    expect(rendered_content).to have_css("button[data-turbo-confirm='Sure?']")
  end

  it "renders a plain button when no path is provided" do
    render_inline(described_class.new(label: "Submit", type: :submit))

    expect(rendered_content).to have_css("button[type='submit']", text: "Submit")
  end

  it "applies extra classes and size modifiers" do
    render_inline(
      described_class.new(
        label: "Compact",
        path: "/projects",
        size: :sm,
        class_name: "rounded-none px-0"
      )
    )

    expect(rendered_content).to have_css("a.rounded-none.px-0", text: "Compact")
  end
end
