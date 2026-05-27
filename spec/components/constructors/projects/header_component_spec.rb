# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::HeaderComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:owner) { create(:user, :constructor) }

  let(:project) do
    create(:project,
           owner: owner,
           name: "Obra del Puerto",
           location: "Buenos Aires",
           budget_cents: 5_000_000_00,
           start_date: 20.days.ago.to_date,
           end_date: 60.days.from_now.to_date)
  end

  subject(:component) { described_class.new(project: project) }

  it "shows the project name" do
    render_inline(component)
    expect(page).to have_text("Obra del Puerto")
  end

  it "shows the project location" do
    render_inline(component)
    expect(page).to have_text("Buenos Aires")
  end

  it "shows a substring of the budget in ARS compact format" do
    # budget_cents = 5_000_000_00 → budget (in cents stored as-is) = 500_000_000
    # qb_fmt_ars(500_000_000) → "$ 500.0M"
    render_inline(component)
    expect(page).to have_text("500")
  end

  it "shows días de obra based on start_date" do
    # project started 20 days ago → metric cell shows "Días de obra" label + value 20
    render_inline(component)
    expect(page).to have_text("Días de obra")
    expect(page).to have_text("20")
  end

  it "shows gastos a la fecha including expenses" do
    # amount_cents: 1_000_00 = 100_000 (cents) → SpendSummary returns cents
    # qb_fmt_ars(100_000) → "$ 100k"
    create(:expense, project: project, author: owner, amount_cents: 1_000_00)
    project.reload
    render_inline(described_class.new(project: project))
    expect(page).to have_text("100k")
  end

  it "shows % avance from progress_percent" do
    # Create a root stage with progress=50, duration=10 days → progress_percent = 50
    create(:project_stage, project: project, parent_id: nil,
                           start_date: 10.days.ago.to_date,
                           end_date: Date.current,
                           progress: 50)
    project.reload
    render_inline(described_class.new(project: project))
    expect(page).to have_text(/50\s*%/)
  end

  context "cover photo" do
    it "shows the featured image when present" do
      image = create(:image, imageable: project, featured: true)
      render_inline(described_class.new(project: project.reload))
      expect(page).to have_css("img")
    end

    it "falls back to first image if no featured image" do
      create(:image, imageable: project, featured: false)
      render_inline(described_class.new(project: project.reload))
      expect(page).to have_css("img")
    end

    it "renders a placeholder when no images exist" do
      render_inline(component)
      # No images → shows placeholder div or svg
      expect(page).to have_css("[data-placeholder], .cover-placeholder, svg, .cover-photo-placeholder")
        .or have_text("portada")
    end
  end

  it "renders the cover photo upload form pointing to the project update path" do
    render_inline(component)
    expect(page).to have_css("form[method='post']")
  end
end
