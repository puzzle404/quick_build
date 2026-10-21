require 'rails_helper'

RSpec.describe Constructors::Projects::PeopleSearchService do
  include ActiveSupport::Testing::TimeHelpers

  describe '#results' do
    let(:project) { create(:project) }

    it 'filters by name and role' do
      matching = create(:project_person, project: project, full_name: 'María González', role_title: 'Ingeniera civil')
      create(:project_person, project: project, full_name: 'Pedro Alfonzo', role_title: 'Maestro mayor')

      results = described_class.new(project: project, query: 'ingeniera').results

      expect(results).to contain_exactly(matching)
    end

    it 'uses start and end dates for range filtering' do
      inside = create(:project_person, project: project, start_date: Date.new(2024, 3, 1), end_date: Date.new(2024, 3, 31))
      create(:project_person, project: project, start_date: Date.new(2023, 7, 1), end_date: Date.new(2023, 9, 1))

      results = described_class.new(
        project: project,
        from_date: '2024-01-01',
        to_date: '2024-04-01'
      ).results

      expect(results).to contain_exactly(inside)
    end
  end
end
