# frozen_string_literal: true

# Flat WBS-style table of root stages and sub-stages, hierarchically indented.
class Constructors::Projects::Planning::WbsTableComponent < ViewComponent::Base
  Row = Struct.new(:stage, :depth, keyword_init: true)

  def initialize(project:, root_stages:)
    @project = project
    @root_stages = Array(root_stages)
  end

  attr_reader :project

  def rows
    out = []
    @root_stages.each do |root|
      decorated_root = ProjectStageDecorator.new(root)
      out << Row.new(stage: decorated_root, depth: 0)
      root.sub_stages.order(:position, :name).each do |sub|
        out << Row.new(stage: ProjectStageDecorator.new(sub), depth: 1)
      end
    end
    out
  end

  def status_tone(stage)
    case stage.status
    when :done then :ok
    when :doing then :info
    else :muted
    end
  end
end
