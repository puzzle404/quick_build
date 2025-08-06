# spec/models/product_spec.rb
require 'rails_helper'

RSpec.describe Product, type: :model do
  subject { build(:product) }
  
  it { should belong_to(:company) }
  it { should validate_presence_of(:name) }
end
