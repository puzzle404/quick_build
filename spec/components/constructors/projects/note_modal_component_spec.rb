# frozen_string_literal: true

require "rails_helper"

RSpec.describe Constructors::Projects::NoteModalComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:owner)   { create(:user, :constructor) }
  let(:project) { create(:project, owner: owner) }
  let(:stage)   { create(:project_stage, project: project) }

  context "without a stage (project-scoped)" do
    before { render_inline described_class.new(project: project) }

    it "renders the modal dialog" do
      expect(page).to have_css("[data-qb--modal-target='dialog']")
    end

    it "shows the heading" do
      expect(page).to have_text("Nueva nota")
    end

    it "posts to the project-scoped notes path" do
      expect(page).to have_css("form[action*='/constructors/projects/#{project.id}/notes']")
    end

    it "does not include the stage in the path" do
      expect(page).not_to have_css(
        "form[action*='/stages/']"
      )
    end

    it "renders body field as required" do
      expect(page).to have_css("textarea[required]")
    end

    it "renders optional title field" do
      expect(page).to have_field("Título")
    end
  end

  context "with a stage (stage-scoped)" do
    before { render_inline described_class.new(project: project, stage: stage) }

    it "posts to the stage-scoped notes path" do
      expect(page).to have_css(
        "form[action*='/constructors/projects/#{project.id}/stages/#{stage.id}/notes']"
      )
    end

    it "mentions the stage in the subtitle" do
      expect(page).to have_text("etapa")
    end
  end
end
