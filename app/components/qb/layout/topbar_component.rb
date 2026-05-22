# frozen_string_literal: true

# Sticky topbar with breadcrumbs (left) and a small action cluster (right).
class Qb::Layout::TopbarComponent < ViewComponent::Base
  renders_one :right_extra

  def initialize(crumbs: [], user: nil, people_on_site: nil, has_alerts: true)
    @crumbs = Array(crumbs)
    @user = user
    @people_on_site = people_on_site
    @has_alerts = has_alerts
  end

  attr_reader :crumbs, :user, :people_on_site, :has_alerts

  def user_short_name
    return 'Usuario' unless user
    name = user.try(:name).presence || user.try(:full_name).presence || user.email.to_s.split('@').first
    name.to_s.titleize
  end

  def user_role
    return nil unless user
    role = user.try(:role).to_s
    return nil if role.blank?
    { 'constructor' => 'Constructor', 'admin' => 'Admin', 'buyer' => 'Cliente', 'seller' => 'Proveedor' }
      .fetch(role, role.titleize)
  end
end
