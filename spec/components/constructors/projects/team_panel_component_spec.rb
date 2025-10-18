# frozen_string_literal: true

require "view_component/test_helpers"
require "capybara/rspec"
require "rails_helper"

RSpec.describe Constructors::Projects::TeamPanelComponent, type: :component do
  include ViewComponent::TestHelpers
  include Capybara::RSpecMatchers
  include Rails.application.routes.url_helpers

  let(:project_record) { create(:project) }
  let(:project) { project_record.decorate }
  let(:membership_form) { project.project_memberships.build }

  context "with members" do
    let!(:membership) { create(:project_membership, project: project_record, role: :admin) }

    it "lists project members and removal action" do
      render_inline(
        described_class.new(project: project, membership: membership_form)
      )

      expect(rendered_content).to have_text(membership.user.email)
      expect(rendered_content).to have_button("Quitar")
    end
  end

  context "without members" do
    it "shows an empty state message" do
      render_inline(
        described_class.new(project: project, membership: membership_form)
      )

      expect(rendered_content).to have_text("Todavía no se agregaron colaboradores")
    end
  end
end
