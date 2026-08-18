# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Project show header", type: :system do
  let(:owner) do
    create(:user, :constructor)
  end

  let(:project) do
    create(:project,
           owner: owner,
           name: "Obra Tribunales",
           location: "Córdoba Capital",
           budget_cents: 10_000_000_00,
           start_date: 15.days.ago.to_date,
           end_date: 90.days.from_now.to_date)
  end

  before { sign_in_user(owner) }

  it "shows name and location in the header" do
    visit constructors_project_path(project)

    expect(page).to have_text("Obra Tribunales")
    expect(page).to have_text("Córdoba Capital")
  end

  it "shows a budget substring in the header" do
    visit constructors_project_path(project)
    # budget_cents = 10_000_000_00 → qb_fmt_cents(1_000_000_00) = qb_fmt_ars(10_000_000) → "$ 10.0M"
    expect(page).to have_text("10.0M")
  end

  it "shows días de obra in the metric strip" do
    visit constructors_project_path(project)
    expect(page).to have_text("Días de obra")
    expect(page).to have_text("15")
  end

  it "shows gastos a la fecha including an expense" do
    create(:expense, project: project, author: owner, amount_cents: 2_000_00)
    visit constructors_project_path(project)
    # amount_cents: 2_000_00 = 200_000 cents → qb_fmt_cents(200_000) = qb_fmt_ars(2_000) → "$ 2k"
    expect(page).to have_text("2k")
  end

  it "shows avance físico from progress_percent" do
    create(:project_stage, project: project, parent_id: nil,
                           start_date: 10.days.ago.to_date,
                           end_date: Date.current,
                           progress: 50)
    visit constructors_project_path(project)
    # progress_percent = 50, shown as "50%"
    expect(page).to have_text("50%")
  end

  it "shows the cover photo upload form" do
    visit constructors_project_path(project)
    expect(page).to have_text("Cambiar portada")
  end
end
