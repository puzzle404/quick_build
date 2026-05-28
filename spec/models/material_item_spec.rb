require "rails_helper"

RSpec.describe MaterialItem, type: :model do
  subject(:material_item) { build(:material_item) }

  it { is_expected.to belong_to(:material_list) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:unit) }
  it { is_expected.to validate_numericality_of(:quantity).is_greater_than_or_equal_to(0) }

  describe "#total_estimated_cost_cents" do
    it "multiplica cantidad por costo" do
      item = build(:material_item, quantity: 2.5, estimated_cost_cents: 400)

      expect(item.total_estimated_cost_cents).to eq(1000)
    end
  end
end
