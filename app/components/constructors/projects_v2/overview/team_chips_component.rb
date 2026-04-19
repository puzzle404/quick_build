# frozen_string_literal: true

# Compact pill of avatars + name initials for team members on a project.
class Constructors::ProjectsV2::Overview::TeamChipsComponent < ViewComponent::Base
  def initialize(members:)
    @members = Array(members)
  end

  attr_reader :members

  def short_name(m)
    name = m.respond_to?(:name) ? m.name : (m.respond_to?(:email) ? m.email.split('@').first : m.to_s)
    name = name.to_s.split('@').first.titleize
    parts = name.split
    return name if parts.size < 2
    "#{parts.first} #{parts[1][0]}."
  end

  def role(m)
    m.respond_to?(:role) ? m.role.to_s.titleize : nil
  end
end
