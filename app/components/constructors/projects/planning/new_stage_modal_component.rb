# frozen_string_literal: true

# Centered modal to create a new ProjectStage. Uses qb--modal Stimulus.
# Submits via Turbo to stages#create. The parent_id select lets the user
# attach the new stage as a sub-stage of an existing root.
class Constructors::Projects::Planning::NewStageModalComponent < ViewComponent::Base
  def initialize(project:, root_stages:)
    @project = project
    @root_stages = root_stages
  end

  attr_reader :project, :root_stages

  def parent_options
    [['— Etapa raíz —', '']] + root_stages.map { |s| [s.try(:code).to_s.empty? ? s.name : "#{s.code} · #{s.name}", s.id] }
  end
end
