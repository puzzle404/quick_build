# frozen_string_literal: true

require "rails_helper"

RSpec.describe Qb::Layout::BottomNavComponent, type: :component do
  it "renders the four primary tabs plus the Más button" do
    render_inline(described_class.new(current: :dashboard))

    expect(page).to have_css("nav.qb-bottom-nav")
    [ "Inicio", "Proyectos", "Personas", "Biblioteca", "Más" ].each do |label|
      expect(page).to have_text(label)
    end
  end

  it "marks the current section as active via aria-current" do
    render_inline(described_class.new(current: :projects))

    expect(page).to have_css('a[aria-current="page"]', text: "Proyectos")
    expect(page).not_to have_css('a[aria-current="page"]', text: "Inicio")
  end

  it "exposes the Más button wired to the bottom sheet" do
    render_inline(described_class.new(current: :dashboard))

    expect(page).to have_css('button[data-action="click->qb--bottom-sheet#open"]', text: "Más")
  end
end
