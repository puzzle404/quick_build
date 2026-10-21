# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::List::GridCardComponent, type: :component do
  it "muestra lo gastado en pesos (antes salía multiplicado por 100)" do
    project = create(:project, budget_cents: 10_000_000_00)
    create(:project_stage, project: project, spent_cents: 1_500_000_00)

    render_inline(described_class.new(project: project.reload))

    expect(page).to have_text("$ 1.5M")
  end
end
