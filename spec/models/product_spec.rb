# spec/models/product_spec.rb
require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { build(:product) }

  it { should belong_to(:company) }
  it { should validate_presence_of(:name) }

  describe '.search_by_name' do
    it 'finds products matching the query' do
      matching = create(:product, name: 'Coffee')
      _other = create(:product, name: 'Tea')

      expect(described_class.search_by_name('Coffee')).to include(matching)
      expect(described_class.search_by_name('Coffee')).not_to include(_other)
    end
  end
end
