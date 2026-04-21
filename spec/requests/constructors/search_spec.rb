require 'rails_helper'

RSpec.describe 'Constructors::Search', type: :request do
  let(:user) { create(:user, :constructor) }
  before { sign_in(user) }

  it 'returns JSON with grouped results' do
    create(:project, owner: user, name: 'Torre Aurora')
    get '/constructors/search.json', params: { q: 'aurora' }
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include('application/json')
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data).to include(:projects, :people, :stages, :documents, :material_lists, :actions)
    expect(data[:projects].first[:label]).to eq('Torre Aurora')
  end

  it 'returns shortcuts even with empty query' do
    get '/constructors/search.json', params: { q: '' }
    data = JSON.parse(response.body, symbolize_names: true)
    expect(data[:actions]).to be_present
  end
end
