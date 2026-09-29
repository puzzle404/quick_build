# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qb::MenuComponent, type: :component do
  it 'renders the trigger with an accessible name and the panel closed' do
    render_inline(described_class.new(items: [ { label: 'Editar', href: '/edit', icon: :edit } ]))

    expect(page).to have_css('[data-controller="qb--dropdown"]')
    expect(page).to have_css('button[aria-label="Más acciones"][data-action="click->qb--dropdown#toggle"]')
    # El controller togglea .hidden; el display:none inline cubre el caso sin [data-theme].
    expect(page).to have_css('[data-qb--dropdown-target="menu"].hidden[style*="display:none"]', visible: :all)
  end

  it 'forwards the data hash verbatim so Turbo keeps working' do
    render_inline(described_class.new(items: [
                                        { label: 'Eliminar', href: '/obras/1', danger: true,
                                          data: { turbo_method: :delete, turbo_confirm: '¿Seguro?',
                                                  turbo_frame: '_top' } }
                                      ]))

    link = page.find('a[role="menuitem"]', visible: :all)
    expect(link['data-turbo-method']).to eq('delete')
    expect(link['data-turbo-confirm']).to eq('¿Seguro?')
    expect(link['data-turbo-frame']).to eq('_top')
    expect(link['style']).to include('var(--color-bad)')
  end

  it 'renders items with a method: as a real form (anda sin JS)' do
    render_inline(described_class.new(items: [
                                        { label: 'Aprobar', href: '/listas/1/aprobar', method: :patch }
                                      ]))

    expect(page).to have_css('form[action="/listas/1/aprobar"]', visible: :all)
    expect(page).to have_css('input[name="_method"][value="patch"]', visible: :all)
  end

  it 'renders nothing when every item was filtered out by a policy guard' do
    render_inline(described_class.new(items: [ nil, nil ]))
    expect(page).not_to have_css('[data-controller="qb--dropdown"]', visible: :all)
  end
end
