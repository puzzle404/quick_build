# frozen_string_literal: true

# Form to upload a blueprint, rendered inside Qb::DrawerComponent. On success
# blueprints_controller#create answers with `turbo_stream.refresh` (Turbo 8
# morphing): the drawer closes because the fresh page brings no content for the
# "drawer" frame, and the whole index re-renders with the new plan in place —
# no page navigation and no hand-written prepend to keep in sync.
class Constructors::Projects::Blueprints::UploadFormComponent < ViewComponent::Base
  def initialize(project:, blueprint:)
    @project = project
    @blueprint = blueprint
  end

  attr_reader :project, :blueprint
end
