require 'rails_helper'

RSpec.describe Support::DateRangeFilter do
  describe '.apply' do
    let(:relation) { Project.all }

    before do
      create(:project, start_date: Date.new(2024, 1, 10))
      create(:project, start_date: Date.new(2023, 12, 15))
    end

    it 'keeps records whose start_date falls within the selected range' do
      scoped = described_class.apply(scope: relation, columns: %w[start_date], from: '2024-01-01', to: '2024-01-31')

      expect(scoped.count).to eq(1)
    end

    it 'handles inverted bounds by swapping them' do
      scoped = described_class.apply(scope: relation, columns: %w[start_date], from: '2024-02-01', to: '2024-01-01')

      expect(scoped.count).to eq(1)
    end

    it 'ignores invalid dates and returns the original relation' do
      scoped = described_class.apply(scope: relation, columns: %w[start_date], from: 'invalid')

      expect(scoped).to eq(relation)
    end
  end
end
