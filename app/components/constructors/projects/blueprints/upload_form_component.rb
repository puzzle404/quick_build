# frozen_string_literal: true

# Form to upload a blueprint, rendered inside Qb::DrawerComponent. On success
# blueprints_controller#create closes the drawer and prepends the new card to
# the index grid — no page navigation needed.
class Constructors::Projects::Blueprints::UploadFormComponent < ViewComponent::Base
  def initialize(project:, blueprint:)
    @project = project
    @blueprint = blueprint
  end

  attr_reader :project, :blueprint
end
