# frozen_string_literal: true

require "view_component/test_helpers"
require "capybara/rspec"
require "rails_helper"

RSpec.describe Constructors::Projects::ProjectHeaderComponent, type: :component do
  include ViewComponent::TestHelpers
  include Capybara::RSpecMatchers
  include Constructors::ProjectsHelper
  include Rails.application.routes.url_helpers

  let(:project) do
    create(
      :project,
      name: "Torre Norte",
      location: "Buenos Aires",
      start_date: Date.new(2024, 1, 10),
      end_date: Date.new(2024, 3, 20)
    ).tap { |proj| proj.update!(updated_at: Time.zone.now) }.decorate
  end

  it "renders key project information and actions" do
    render_inline(described_class.new(project: project))

    expect(rendered_content).to have_css("h1", text: "Torre Norte")
    expect(rendered_content).to have_text(project.location_label)
    expect(rendered_content).to have_text("Inicio programado")
    expect(rendered_content).to have_link("Editar obra", href: edit_constructors_project_path(project))
    expect(rendered_content).to have_link("Volver a mis obras", href: constructors_projects_path)
  end
end
