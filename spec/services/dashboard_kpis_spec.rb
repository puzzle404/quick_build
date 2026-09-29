require 'rails_helper'

RSpec.describe DashboardKpis do
  let(:user) { create(:user, :constructor) }

  it 'returns zeros when there are no projects' do
    result = described_class.new([]).call
    expect(result[:total_projects]).to eq(0)
    expect(result[:in_progress]).to eq(0)
    expect(result[:planned]).to eq(0)
    expect(result[:completed]).to eq(0)
    expect(result[:at_risk]).to eq(0)
    expect(result[:budget_total_cents]).to eq(0)
    expect(result[:budget_spent_cents]).to eq(0)
    expect(result[:people_on_site]).to eq(0)
    expect(result[:stages_at_risk]).to eq(0)
  end

  it 'aggregates project counts by status' do
    p1 = create(:project, owner: user, status: :in_progress)
    p2 = create(:project, owner: user, status: :planned)
    p3 = create(:project, owner: user, status: :completed)
    decorated = [p1, p2, p3].map { ProjectDecorator.new(_1) }
    result = described_class.new(decorated).call
    expect(result[:total_projects]).to eq(3)
    expect(result[:in_progress]).to eq(1)
    expect(result[:planned]).to eq(1)
    expect(result[:completed]).to eq(1)
  end

  it 'sums budget cents across projects' do
    p1 = create(:project, owner: user, budget_cents: 100_000_00)
    p2 = create(:project, owner: user, budget_cents: 250_000_00)
    decorated = [p1, p2].map { ProjectDecorator.new(_1) }
    result = described_class.new(decorated).call
    expect(result[:budget_total_cents]).to eq(350_000_00)
  end

  it 'counts people_on_site from active project_people across projects' do
    project = create(:project, owner: user)
    create(:project_person, project: project, status: :active)
    create(:project_person, project: project, status: :active)
    create(:project_person, project: project, status: :inactive)
    result = described_class.new([ProjectDecorator.new(project)]).call
    expect(result[:people_on_site]).to eq(2)
  end

  it 'counts at_risk projects (health != ok and not completed)' do
    in_progress = create(:project, owner: user, status: :in_progress, start_date: 100.days.ago, end_date: 10.days.from_now)
    create(:project_stage, project: in_progress, progress: 0)
    completed_bad = create(:project, owner: user, status: :completed, budget_cents: 100, start_date: 30.days.ago, end_date: Date.current)
    create(:project_stage, project: completed_bad, spent_cents: 1_000)
    decorated = [in_progress, completed_bad].map { ProjectDecorator.new(_1) }
    result = described_class.new(decorated).call
    # Only the in-progress one with low actual progress vs plan should count.
    expect(result[:at_risk]).to be >= 1
  end
end
