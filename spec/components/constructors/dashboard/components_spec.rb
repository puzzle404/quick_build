require 'rails_helper'

RSpec.describe 'Dashboard v2 components', type: :component do
  describe Constructors::Dashboard::HeroCardComponent do
    it 'renders value, hint, and a CTA link' do
      with_request_url '/constructors' do
        render_inline(described_class.new(
          variant: :violet, icon: :projects, label: 'Obras totales',
          value: 7, hint: '5 activas', cta_label: 'Ver proyectos', cta_href: '/constructors/projects'
        ))
      end
      expect(page).to have_text('Obras totales')
      expect(page).to have_text('7')
      expect(page).to have_text('5 activas')
      expect(page).to have_link('Ver proyectos', href: '/constructors/projects')
    end

    it 'renders progress bar when progress is given' do
      rendered = render_inline(described_class.new(
        variant: :amber, icon: :zap, label: 'En progreso',
        value: 3, progress: 42, cta_label: '→', cta_href: '#'
      ))
      expect(rendered.to_html).to include('width:42%')
    end
  end

  describe Constructors::Dashboard::KpiBlockComponent do
    it 'renders label, value and inline sparkline' do
      render_inline(described_class.new(label: 'Hs', value: '1.842', hint: '+4 vs ayer', tone: :ok, data: [1, 2, 3]))
      expect(page).to have_text('Hs')
      expect(page).to have_text('1.842')
      expect(page).to have_css('svg polyline')
    end
  end

  describe Constructors::Dashboard::EvolutionChartComponent do
    it 'renders an SVG with grid lines and series' do
      rendered = render_inline(described_class.new(months: %w[Nov Dic Ene], spend: [10, 20, 30], progress: [10, 20, 30], plan: [15, 25, 35]))
      html = rendered.to_html
      expect(html).to include('<svg')
      expect(html).to include('100%')  # axis labels
      expect(html).to include('Nov')
    end
  end

  describe Constructors::Dashboard::ProjectsTableComponent do
    let!(:user) { create(:user, :constructor) }
    let!(:project) { create(:project, owner: user, status: :in_progress) }

    it 'renders table headers and one project row' do
      with_request_url '/constructors' do
        render_inline(described_class.new(rows: [project]))
      end
      expect(page).to have_text(project.name)
      expect(page).to have_text('Avance')
      expect(page).to have_text('Curva S')
    end
  end

  describe Constructors::Dashboard::ActivityFeedComponent do
    it 'renders an empty state when there are no entries' do
      render_inline(described_class.new(entries: []))
      expect(page).to have_text('Sin actividad reciente')
    end

    it 'renders provided entries' do
      entries = [{ title: 'Proyecto X — Etapa creada', timestamp: 2.hours.ago }]
      render_inline(described_class.new(entries: entries))
      expect(page).to have_text('Proyecto X — Etapa creada')
      expect(page).to have_text(/Hace \d+ h/)
    end
  end

  describe Constructors::Dashboard::AlertStripComponent do
    it 'shows empty state when nothing is at risk' do
      render_inline(described_class.new(projects: []))
      expect(page).to have_text('Sin alertas activas.')
    end

    it 'derives alerts from at-risk projects' do
      proj = double('Proj', health: :warn, status: :in_progress, code: 'PRJ-042', name: 'Aurora',
                            planned_progress: 60, progress: 40, spent: 0, budget: 100)
      render_inline(described_class.new(projects: [proj]))
      expect(page).to have_text('Avance físico')
      expect(page).to have_text('PRJ-042')
    end
  end

  describe Constructors::Dashboard::UpcomingStagesComponent do
    it 'renders empty state when there are no stages' do
      render_inline(described_class.new(stages: []))
      expect(page).to have_text('No hay etapas planificadas próximas.')
    end
  end
end
