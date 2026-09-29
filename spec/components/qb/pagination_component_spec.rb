require 'rails_helper'

RSpec.describe Qb::PaginationComponent, type: :component do
  let(:pagy_one)  { Pagy.new(count: 5,  limit: 25) }
  let(:pagy_many) { Pagy.new(count: 75, limit: 25, page: 2) }

  it 'does not render when there is a single page' do
    expect(described_class.new(pagy: pagy_one).render?).to be false
  end

  it 'renders the count and a nav with prev/next' do
    render_inline(described_class.new(pagy: pagy_many, label: 'obras'))
    expect(page).to have_text('Mostrando 26–50 de 75 obras')
    expect(page).to have_css('nav[aria-label="Paginación"]')
    expect(page).to have_link('←', href: '?page=1')
    expect(page).to have_link('→', href: '?page=3')
  end

  it 'highlights the current page with aria-current' do
    rendered = render_inline(described_class.new(pagy: pagy_many))
    expect(rendered.to_html).to include('aria-current="page"')
  end
end
