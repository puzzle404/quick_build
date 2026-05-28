require 'rails_helper'

RSpec.describe Constructors::Projects::MaterialListSearchService do
  include ActiveSupport::Testing::TimeHelpers
  describe '#results' do
    let(:project) { create(:project) }

    it 'matches lists by name and notes' do
      matching = create(:material_list, project: project, name: 'Instalación eléctrica', notes: 'Cables y tomas')
      create(:material_list, project: project, name: 'Estructura metálica', notes: 'Pilares', add_default_item: false)

      results = described_class.new(project: project, query: 'eléctrica').results

      expect(results).to contain_exactly(matching)
    end

    it 'filters by last update window' do
      recent = nil
      travel_to Date.new(2024, 1, 10) do
        recent = create(:material_list, project: project, add_default_item: false)
      end

      travel_to Date.new(2023, 8, 5) do
        create(:material_list, project: project, add_default_item: false)
      end

      results = described_class.new(project: project, from_date: '2024-01-01').results

      expect(results).to contain_exactly(recent)
    end
  end
end
