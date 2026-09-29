require 'rails_helper'

RSpec.describe 'Products', type: :request do
  let(:user) { create(:user) }

  describe 'GET /products' do
    it 'returns products matching the search term' do
      sign_in(user)
      create(:product, name: 'Coffee')
      create(:product, name: 'Tea')

      get products_path, params: { query: 'Coffee' }
      expect(response.body).to include('Coffee')
      expect(response.body).not_to include('Tea')
    end
  end
end
