require 'rails_helper'

RSpec.describe Constructors::Projects::ProjectSearchService do
  describe '#results' do
    let(:owner) { create(:user, :constructor) }

    it 'filters projects by query keywords' do
      matching = create(:project, owner: owner, name: 'Edificio Central', location: 'Rosario')
      create(:project, owner: owner, name: 'Parque Industrial', location: 'Córdoba')

      results = described_class.new(scope: owner.owned_projects, query: 'central').results

      expect(results).to contain_exactly(matching)
    end

    it 'applies date range filters using start and end dates' do
      inside = create(:project, owner: owner, start_date: Date.new(2024, 2, 1), end_date: Date.new(2024, 3, 1))
      create(:project, owner: owner, start_date: Date.new(2023, 1, 1), end_date: Date.new(2023, 6, 1))

      results = described_class.new(
        scope: owner.owned_projects,
        from_date: '2024-01-15',
        to_date: '2024-03-10'
      ).results

      expect(results).to contain_exactly(inside)
    end
  end
end
