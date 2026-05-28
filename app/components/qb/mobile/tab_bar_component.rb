# frozen_string_literal: true

# Bottom tab bar (5 tabs). Only rendered in plain-browser previews; the
# Hotwire Native iOS shell provides the real UITabBarController.
class Qb::Mobile::TabBarComponent < ViewComponent::Base
  # `key` matches the same `current_qb_section` symbols used in the desktop
  # sidebar, so existing controllers don't need to change.
  TABS = [
    { key: :dashboard, label: 'Inicio',    icon: :home,     path_helper: :constructors_root_path },
    { key: :projects,  label: 'Proyectos', icon: :projects, path_helper: :constructors_projects_path },
    { key: :search,    label: 'Buscar',    icon: :search,   path_helper: :constructors_search_path },
    { key: :library,   label: 'Biblio.',   icon: :library,  path_helper: :constructors_library_path },
    { key: :profile,   label: 'Perfil',    icon: :user,     path_helper: :edit_registration_path },
  ].freeze

  def initialize(active: :dashboard)
    @active = active&.to_sym
  end

  def safe_path(helper)
    helpers.public_send(helper)
  rescue NoMethodError, ActionController::UrlGenerationError
    '#'
  end
end
