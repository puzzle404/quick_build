# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qb::TabbedPanelComponent, type: :component do
  subject(:rendered) do
    render_inline(described_class.new) do |tp|
      tp.with_tab(label: 'A', count: 2) { 'PanelA' }
      tp.with_tab(label: 'B') { 'PanelB' }
    end
  end

  it 'renders a tab button per with_tab' do
    rendered
    expect(page).to have_css('button.qb-tab', count: 2)
    expect(page).to have_css('button.qb-tab', text: /A/)
    expect(page).to have_css('button.qb-tab', text: /B/)
  end

  it 'renders the count badge when count is given' do
    rendered
    expect(page).to have_css('button.qb-tab span.qb-tab-count', text: '2')
  end

  it 'does not render a count badge when count is nil' do
    rendered
    # Second tab has no count, so only one count badge total
    expect(page).to have_css('span.qb-tab-count', count: 1)
  end

  it 'gives the first tab the active class' do
    rendered
    expect(page).to have_css('button.qb-tab.qb-tab--active', text: /A/)
  end

  it 'does not give the second tab the active class' do
    rendered
    expect(page).not_to have_css('button.qb-tab.qb-tab--active', text: /B/)
  end

  it 'makes the first panel visible (no display:none)' do
    html = rendered.to_html
    first_panel = html[/data-index="0"[^>]*>(.*?)<\/div>/m]
    expect(html).to include('data-index="0"')
    # The first panel div should NOT have display:none
    first_panel_tag = html.match(/<div[^>]*data-qb--tabs-target="panel"[^>]*data-index="0"[^>]*>/)
    expect(first_panel_tag.to_s).not_to include('display:none')
  end

  it 'ships all panels visible (no display:none in markup — qb--tabs hides on connect for rack_test compat)' do
    html = rendered.to_html
    second_panel_tag = html.match(/<div[^>]*data-qb--tabs-target="panel"[^>]*data-index="1"[^>]*>/)
    expect(second_panel_tag.to_s).not_to include('display:none')
    expect(page).to have_css('div[data-qb--tabs-target="panel"]', count: 2)
  end

  it 'renders the panel block content' do
    rendered
    expect(page).to have_text('PanelA')
    expect(page).to have_text('PanelB')
  end

  it 'wraps everything in a data-controller="qb--tabs" div' do
    rendered
    expect(page).to have_css('div[data-controller="qb--tabs"]')
  end

  it 'wires tabs with data-action for the Stimulus controller' do
    rendered
    expect(page).to have_css('button[data-action="click->qb--tabs#select"]', count: 2)
  end
end
