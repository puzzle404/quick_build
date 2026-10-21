# frozen_string_literal: true

require "view_component/test_helpers"
require "capybara/rspec"
require "rails_helper"

RSpec.describe Ui::MetricCardComponent, type: :component do
  include ViewComponent::TestHelpers
  include Capybara::RSpecMatchers

  it "renders the provided title and value" do
    render_inline(
      described_class.new(
        title: "Duración",
        value: "12 semanas",
        description: "Incluye etapas de planificación"
      )
    )

    expect(rendered_content).to have_text("Duración")
    expect(rendered_content).to have_text("12 semanas")
    expect(rendered_content).to have_text("Incluye etapas de planificación")
  end

  it "shows placeholder when value is blank" do
    render_inline(described_class.new(title: "Duración", value: nil))

    expect(rendered_content).to have_text("—")
  end
end
