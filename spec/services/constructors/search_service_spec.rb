require 'rails_helper'

RSpec.describe Constructors::SearchService do
  let(:user)  { create(:user, :constructor) }
  let(:other) { create(:user, :constructor) }

  it 'returns empty groups (except actions) when query is blank' do
    create(:project, owner: user, name: 'Aurora')
    result = described_class.new(user: user, query: '').call
    expect(result[:projects]).to be_an(Array)
    # Empty query → projects list still returns recents (no q filter), people/stages/etc are []
    expect(result[:people]).to eq([])
    expect(result[:stages]).to eq([])
    expect(result[:documents]).to eq([])
    expect(result[:material_lists]).to eq([])
    expect(result[:actions]).to all(have_key(:label))
  end

  it 'finds projects by name (pg_search)' do
    create(:project, owner: user, name: 'Torre Aurora')
    create(:project, owner: user, name: 'Casa Pilar')
    result = described_class.new(user: user, query: 'aurora').call
    labels = result[:projects].map { |p| p[:label] }
    expect(labels).to include('Torre Aurora')
    expect(labels).not_to include('Casa Pilar')
  end

  it 'finds projects by ID-like query (PRJ-NN)' do
    p = create(:project, owner: user, name: 'Aurora')
    result = described_class.new(user: user, query: "prj-#{p.id}").call
    expect(result[:projects].map { |x| x[:id] }).to include(p.id)
  end

  it 'never returns projects from other constructors' do
    create(:project, owner: other, name: 'Foreign Project')
    result = described_class.new(user: user, query: 'foreign').call
    expect(result[:projects]).to eq([])
  end

  it 'finds people by full_name' do
    project = create(:project, owner: user)
    create(:project_person, project: project, full_name: 'Pedro García')
    result = described_class.new(user: user, query: 'pedro').call
    expect(result[:people].first[:label]).to eq('Pedro García')
  end

  it 'finds stages by name' do
    project = create(:project, owner: user)
    create(:project_stage, project: project, name: 'Mampostería')
    result = described_class.new(user: user, query: 'mampo').call
    expect(result[:stages].first[:label]).to eq('Mampostería')
  end

  it 'finds material lists by name' do
    project = create(:project, owner: user)
    create(:material_list, project: project, author: user, name: 'Hierros estructura')
    result = described_class.new(user: user, query: 'hierros').call
    expect(result[:material_lists].first[:label]).to eq('Hierros estructura')
  end

  it 'returns action shortcuts always (filtered by query)' do
    result = described_class.new(user: user, query: 'crear').call
    labels = result[:actions].map { |a| a[:label] }
    expect(labels).to include('Crear nuevo proyecto')
  end
end
