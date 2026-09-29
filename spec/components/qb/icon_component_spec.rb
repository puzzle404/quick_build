require 'rails_helper'

RSpec.describe Qb::IconComponent, type: :component do
  it 'renders the requested glyph' do
    render_inline(described_class.new(name: :home))
    expect(page).to have_css('svg path')
  end

  it 'uses 24x24 viewBox by default' do
    rendered = render_inline(described_class.new(name: :search))
    # Nokogiri's HTML parser lowercases attribute names; check case-insensitively.
    expect(rendered.to_html.downcase).to include('viewbox="0 0 24 24"')
  end

  it 'respects size prop' do
    render_inline(described_class.new(name: :search, size: 24))
    expect(page).to have_css('svg[width="24"][height="24"]')
  end

  it 'falls back to a dot for unknown names' do
    render_inline(described_class.new(name: :nonexistent))
    expect(page).to have_css('svg circle')
  end

  it 'applies optional css_class and style' do
    render_inline(described_class.new(name: :plus, css_class: 'foo', style: 'color:red'))
    expect(page).to have_css('svg.foo[style*="color:red"]')
  end
end
