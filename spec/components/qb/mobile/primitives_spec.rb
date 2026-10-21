require 'rails_helper'

RSpec.describe 'Qb::Mobile primitives', type: :component do
  describe Qb::Mobile::ButtonComponent do
    it 'dasherizes data attribute keys so Turbo picks them up' do
      rendered = render_inline(described_class.new('Aplicar plantilla', href: '/x', data: { turbo_method: :post }))
      expect(rendered.to_html).to include('data-turbo-method="post"')
      expect(rendered.to_html).not_to include('data-turbo_method')
    end

    it 'keeps already-dashed keys untouched' do
      rendered = render_inline(described_class.new('Ver', href: '/x', data: { 'turbo-frame' => '_top' }))
      expect(rendered.to_html).to include('data-turbo-frame="_top"')
    end

    it 'renders a button when href is absent' do
      rendered = render_inline(described_class.new('Guardar'))
      expect(rendered.to_html).to include('<button')
    end
  end

  describe Qb::Mobile::RowComponent do
    it 'dasherizes data attribute keys' do
      rendered = render_inline(described_class.new(title: 'Fila', href: '/x', data: { turbo_confirm: '¿Seguro?' }))
      expect(rendered.to_html).to include('data-turbo-confirm=')
      expect(rendered.to_html).not_to include('data-turbo_confirm')
    end
  end

  describe Qb::Mobile::CardComponent do
    it 'dasherizes data attribute keys' do
      rendered = render_inline(described_class.new(href: '/x', data: { turbo_method: :delete })) { 'Contenido' }
      expect(rendered.to_html).to include('data-turbo-method="delete"')
      expect(rendered.to_html).not_to include('data-turbo_method')
    end
  end

  describe Qb::Mobile::FormPickerRowComponent do
    it 'renders a link with chevron when href is given' do
      rendered = render_inline(described_class.new(label: 'Obra', value: 'Torre Norte', href: '/pick'))
      expect(rendered.to_html).to include('<a')
      expect(rendered.to_html).to include('m-frow-picker')
      expect(rendered.to_html).to include('<svg')
    end

    it 'renders a non-interactive div without chevron when href is nil' do
      rendered = render_inline(described_class.new(label: 'Etapa padre', value: 'Fundaciones', href: nil))
      expect(rendered.to_html).to include('<div class="m-frow-picker"')
      expect(rendered.to_html).not_to include('<button')
      expect(rendered.to_html).not_to include('<a ')
      expect(rendered.to_html).not_to include('<svg')
    end
  end
end
