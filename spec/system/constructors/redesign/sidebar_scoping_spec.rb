require 'rails_helper'

# Regression: the sidebar's pinned list and the cmd palette used to query
# Project.all and would surface other constructors' projects, leading to
# 404s when the user clicked through. They must now scope to owned_projects.
RSpec.describe 'QB OS · sidebar/cmd-palette scoping', type: :system do
  let(:owner) { create(:user, :constructor, email: 'me@example.com') }
  let(:other) { create(:user, :constructor, email: 'other@example.com') }
  before do
    create(:project, owner: owner, name: 'My Aurora')
    create(:project, owner: other, name: 'Foreign Pilar')
    sign_in_user(owner)
  end

  it 'shows only owned projects in the sidebar Fijados list' do
    visit constructors_root_path
    within('aside.qb-sidebar') do
      expect(page).to have_text('My Aurora')
      expect(page).not_to have_text('Foreign Pilar')
    end
  end

  it 'shows only owned projects in the cmd palette items' do
    visit constructors_root_path
    # Cmd palette is in the body but hidden; assert the items exist scoped to owner.
    expect(page).to have_text('My Aurora')
    expect(page).not_to have_text('Foreign Pilar')
  end

  it 'project_count badge reflects owned scope only' do
    visit constructors_root_path
    within('aside.qb-sidebar') do
      # Owner has 1 project; badge should be "1", not "2"
      expect(page).to have_text(/Proyectos\s+1/)
    end
  end
end
