require 'rails_helper'

RSpec.describe 'Qb primitives', type: :component do
  describe Qb::StatusDotComponent do
    it 'renders a span with background color' do
      render_inline(described_class.new(tone: :ok))
      expect(page).to have_css('span[style*="background"]')
    end

    it 'falls back to muted for unknown tones' do
      expect { render_inline(described_class.new(tone: :unknown)) }.not_to raise_error
    end
  end

  describe Qb::PillComponent do
    it 'renders content inside a span' do
      render_inline(described_class.new) { 'Aprobada' }
      expect(page).to have_text('Aprobada')
    end

    it 'supports compact + mono modifiers' do
      rendered = render_inline(described_class.new(tone: :warn, mono: true, compact: true)) { 'X' }
      expect(rendered.to_html).to include('var(--font-mono)')
      expect(rendered.to_html).to include('1px 6px')
    end
  end

  describe Qb::BarComponent do
    it 'renders the value as inner-bar width' do
      rendered = render_inline(described_class.new(value: 42))
      expect(rendered.to_html).to include('width:42%')
    end

    it 'caps over-100 values' do
      rendered = render_inline(described_class.new(value: 999))
      expect(rendered.to_html).to include('width:100%')
    end

    it 'renders a plan marker when show_plan is true' do
      rendered = render_inline(described_class.new(value: 30, plan: 50, show_plan: true))
      expect(rendered.to_html).to include('left:50%')
    end
  end

  describe Qb::StackedBarComponent do
    it 'renders three segments proportional to total' do
      rendered = render_inline(described_class.new(spent: 25, committed: 25, total: 100))
      expect(rendered.to_html).to include('width:25%')
    end
  end

  describe Qb::AvatarComponent do
    it 'renders the initials of the given name' do
      render_inline(described_class.new(name: 'María Fernández'))
      expect(page).to have_text('MF')
    end

    it 'falls back to ?? when name is blank' do
      render_inline(described_class.new(name: nil))
      expect(page).to have_text('??')
    end
  end

  describe Qb::SectionHeadComponent do
    it 'renders title and subtitle' do
      render_inline(described_class.new(title: 'Sección', subtitle: 'detalle'))
      expect(page).to have_text('Sección')
      expect(page).to have_text('detalle')
    end

    it 'renders right slot when given' do
      render_inline(described_class.new(title: 'X')) do |c|
        c.with_right { 'right-side' }
      end
      expect(page).to have_text('right-side')
    end
  end

  describe Qb::MetricCellComponent do
    it 'renders label, value, and hint' do
      render_inline(described_class.new(label: 'Avance', value: '64%', hint: 'plan 68%'))
      expect(page).to have_text('Avance')
      expect(page).to have_text('64%')
      expect(page).to have_text('plan 68%')
    end

    it 'colours value by tone' do
      rendered = render_inline(described_class.new(label: 'X', value: '1', tone: :warn))
      expect(rendered.to_html).to include('var(--color-warn)')
    end
  end

  describe Qb::SparkComponent do
    it 'returns an empty SVG when data is empty' do
      rendered = render_inline(described_class.new(data: []))
      expect(rendered.to_html).to include('<svg')
    end

    it 'renders polylines for data + plan' do
      rendered = render_inline(described_class.new(data: [1, 2, 3], plan: [2, 2, 2]))
      expect(rendered.to_html.scan('polyline').size).to be >= 2
    end
  end

  describe Qb::BtnComponent do
    it 'renders as <button> by default' do
      render_inline(described_class.new) { 'Click' }
      expect(page).to have_css('button', text: 'Click')
    end

    it 'renders as <a> when href is given' do
      render_inline(described_class.new(href: '/foo')) { 'Ir' }
      expect(page).to have_css('a[href="/foo"]', text: 'Ir')
    end

    it 'inserts the icon on the left' do
      rendered = render_inline(described_class.new(icon: :plus)) { 'Nuevo' }
      expect(rendered.to_html).to include('<svg')
      expect(page).to have_text('Nuevo')
    end

    it 'applies primary variant styles' do
      rendered = render_inline(described_class.new(variant: :primary)) { 'OK' }
      expect(rendered.to_html).to include('var(--color-accent)')
    end
  end

  describe Qb::TabsComponent do
    let(:tabs) do
      [
        { value: :a, label: 'Resumen', icon: :home, href: '#a' },
        { value: :b, label: 'Materiales', icon: :materials, count: 12, href: '#b' },
      ]
    end

    it 'renders all tabs' do
      render_inline(described_class.new(tabs: tabs, current: :a))
      expect(page).to have_text('Resumen')
      expect(page).to have_text('Materiales')
      expect(page).to have_text('12')
    end

    it 'highlights the current tab' do
      rendered = render_inline(described_class.new(tabs: tabs, current: :b))
      expect(rendered.to_html).to include('var(--color-accent)')
    end

    it 'renders the right slot' do
      render_inline(described_class.new(tabs: tabs, current: :a)) do |c|
        c.with_right { 'side' }
      end
      expect(page).to have_text('side')
    end
  end
end
