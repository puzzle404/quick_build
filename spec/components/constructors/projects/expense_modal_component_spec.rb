# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::ExpenseModalComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage)   { create(:project_stage, project: project) }

  context "without a stage (project-scoped)" do
    before { render_inline described_class.new(project: project) }

    it "renders the modal dialog" do
      expect(page).to have_css("[data-qb--modal-target='dialog']")
    end

    it "posts to the project-scoped expenses path" do
      expect(page).to have_css("form[action*='/constructors/projects/#{project.id}/expenses']")
    end

    it "shows the default heading" do
      expect(page).to have_text("Registrar nuevo gasto")
    end

    it "does not post to a stage-scoped path" do
      expect(page).not_to have_css("form[action*='/stages/']")
    end
  end

  context "with a stage (stage-scoped)" do
    before { render_inline described_class.new(project: project, stage: stage) }

    it "posts to the stage-scoped expenses path" do
      expect(page).to have_css(
        "form[action*='/constructors/projects/#{project.id}/stages/#{stage.id}/expenses']"
      )
    end

    it "mentions the stage in the subtitle" do
      expect(page).to have_text("etapa")
    end
  end
end
