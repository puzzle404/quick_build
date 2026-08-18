# frozen_string_literal: true

# Right-side drawer to create a new ProjectStage. Click-driven qb--drawer
# instance (no dedicated #new route to frame-scope against — stages#new
# exists but its drawer has no "Etapa padre" selector, so this stays a
# self-contained, client-side-only drawer like InviteMemberDrawerComponent).
# Submits via Turbo to stages#create. The parent_id select lets the user
# attach the new stage as a sub-stage of an existing root.
class Constructors::Projects::Planning::NewStageDrawerComponent < ViewComponent::Base
  def initialize(project:, root_stages:)
    @project = project
    @root_stages = root_stages
  end

  attr_reader :project, :root_stages

  def parent_options
    [['— Etapa raíz —', '']] + root_stages.map { |s| [s.try(:code).to_s.empty? ? s.name : "#{s.code} · #{s.name}", s.id] }
  end
end
