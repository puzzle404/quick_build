# frozen_string_literal: true

# Definición compartida de la navegación del Constructor OS: secciones
# primarias + sub-nav por proyecto. Se mezcla en SidebarComponent (rail de
# escritorio) y BottomNavComponent (tabs mobile) para que ambos no diverjan.
#
# La clase que lo incluye debe exponer +current+, +project+ y +project_sub+.
module Qb
  module Layout
    module Navigation
      NAV = [
        { key: :dashboard, label: "Dashboard",  icon: :dashboard },
        { key: :projects,  label: "Proyectos",  icon: :projects, badge_kind: :project_count },
        { key: :team,      label: "Personas",   icon: :people },
        { key: :docs,      label: "Biblioteca", icon: :docs }
      ].freeze

      PROJECT_NAV = [
        { key: :overview,   label: "Resumen",       icon: :home },
        { key: :planning,   label: "Planificación", icon: :planning },
        { key: :materials,  label: "Materiales",    icon: :materials },
        { key: :blueprints, label: "Planos · IA",   icon: :blueprint, accent: true },
        { key: :team,       label: "Equipo",        icon: :people },
        { key: :docs,       label: "Documentos",    icon: :docs }
      ].freeze

      def nav_items
        NAV.map { |n| n.merge(active: n[:key] == current, url: nav_url(n[:key])) }
      end

      def project_nav_items
        return [] unless project

        PROJECT_NAV.map { |n| n.merge(active: n[:key] == project_sub, url: project_url(n[:key])) }
      end

      def project_url(sub_key)
        case sub_key
        when :overview   then helpers.constructors_project_path(project)
        when :planning   then helpers.constructors_project_planning_path(project)
        when :materials  then helpers.constructors_project_material_lists_path(project)
        when :blueprints then helpers.constructors_project_blueprints_path(project)
        when :team       then helpers.constructors_project_people_path(project)
        when :docs       then helpers.constructors_project_documents_path(project)
        end
      rescue NoMethodError
        "#"
      end

      def nav_url(key)
        case key
        when :dashboard then helpers.constructors_root_path
        when :projects  then helpers.constructors_projects_path
        when :team      then helpers.constructors_people_path
        when :docs      then helpers.constructors_projects_path
        else "#"
        end
      rescue NoMethodError
        "#"
      end

      def new_project_url
        helpers.new_constructors_project_path
      rescue NoMethodError
        "#"
      end
    end
  end
end
