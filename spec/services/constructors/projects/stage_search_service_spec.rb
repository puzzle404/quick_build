require 'rails_helper'

RSpec.describe Constructors::Projects::StageSearchService do
  describe '#main_stages' do
    it 'filters stages within the provided date range' do
      project = create(:project)
      inside_stage = create(:project_stage, project: project, start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 1, 10))
      outside_stage = create(:project_stage, project: project, start_date: Date.new(2024, 3, 1), end_date: Date.new(2024, 3, 15))

      service = described_class.new(project: project, from_date: '2024-01-05', to_date: '2024-01-20')

      expect(service.main_stages).to match_array([inside_stage])
      expect(service.main_stages).not_to include(outside_stage)
    end
  end

  describe '#sub_stages' do
    it 'returns sub stages matching the lower bound filter' do
      project = create(:project)
      parent = create(:project_stage, project: project)

      inside_sub_stage = create(:project_stage, project: project, parent: parent, start_date: Date.new(2024, 2, 1), end_date: Date.new(2024, 2, 5))
      create(:project_stage, project: project, parent: parent, start_date: Date.new(2023, 6, 1), end_date: Date.new(2023, 6, 10))

      service = described_class.new(project: project, from_date: '2024-02-01')

      expect(service.sub_stages).to match_array([inside_sub_stage])
    end
  end
end
