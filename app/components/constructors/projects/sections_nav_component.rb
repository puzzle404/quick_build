class Constructors::Projects::SectionsNavComponent < ViewComponent::Base
  def initialize(project:, current_section:)
    @project = project
    @current_section = current_section
  end

  def sections
    @sections ||= [
      {
        key: :overview,
        name: "Resumen general",
        description: "Estado y actividad de la obra",
        path: helpers.constructors_project_path(@project)
      },
      {
        key: :materials,
        name: "Listas de materiales",
        description: "Insumos, cantidades y archivos",
        path: helpers.constructors_project_material_lists_path(@project)
      },
      {
        key: :people,
        name: "Recursos humanos",
        description: "Roles y disponibilidad",
        path: helpers.constructors_project_people_path(@project)
      },
      {
        key: :planning,
        name: "Planificación",
        description: "WBS, hitos y cronogramas",
        path: helpers.constructors_project_planning_path(@project)
      },
      {
        key: :documents,
        name: "Documentos",
        description: "Contratos, planos y reportes",
        path: helpers.constructors_project_documents_path(@project)
      }
    ]
  end

  def nav_item_classes(section)
    base = "inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm font-semibold transition"

    if current?(section)
      "#{base} border-indigo-500 bg-indigo-50 text-indigo-700 shadow-sm"
    elsif section[:path].present?
      "#{base} border-slate-200 bg-white text-slate-600 hover:border-indigo-200 hover:text-indigo-700"
    else
      "#{base} cursor-not-allowed border-dashed border-slate-200 bg-slate-50 text-slate-400"
    end
  end

  def badge_for(section)
    if section[:soon]
      content_tag(:span, "Próx.", class: "rounded-full bg-slate-200 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-slate-600")
    elsif current?(section)
      content_tag(:span, "Activo", class: "text-[10px] font-semibold uppercase tracking-wide text-indigo-600")
    else
      nil
    end
  end

  def current?(section)
    section[:key] == @current_section
  end
end
