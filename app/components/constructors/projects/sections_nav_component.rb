class Constructors::Projects::SectionsNavComponent < ViewComponent::Base
  def initialize(project:, current_section:)
    @project = project
    @current_section = current_section
  end

  def sections
    @sections ||= [
      {
        key: :overview,
        name: "Resumen",
        description: "Estado y actividad de la obra",
        path: helpers.constructors_project_path(@project),
        icon: "home"
      },
      {
        key: :materials,
        name: "Materiales",
        description: "Insumos, cantidades y archivos",
        path: helpers.constructors_project_material_lists_path(@project),
        icon: "clipboard",
        highlight: true
      },
      {
        key: :blueprints,
        name: "Planos",
        description: "Medición y cálculo con IA",
        path: helpers.constructors_project_blueprints_path(@project),
        icon: "map"
      },
      {
        key: :people,
        name: "Equipo",
        description: "Roles y disponibilidad",
        path: helpers.constructors_project_people_path(@project),
        icon: "users"
      },
      {
        key: :planning,
        name: "Planificación",
        description: "Etapas y cronogramas",
        path: helpers.constructors_project_planning_path(@project),
        icon: "calendar"
      },
      {
        key: :documents,
        name: "Documentos",
        description: "Contratos y reportes",
        path: helpers.constructors_project_documents_path(@project),
        icon: "folder"
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

  def icon_for(icon_name)
    icons = {
      home: '<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25" /></svg>',
      clipboard: '<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z" /></svg>',
      map: '<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9 6.75V15m6-6v8.25m.503 3.498l4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 00-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0z" /></svg>',
      users: '<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z" /></svg>',
      calendar: '<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5" /></svg>',
      folder: '<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12.75V12A2.25 2.25 0 014.5 9.75h15A2.25 2.25 0 0121.75 12v.75m-8.69-6.44l-2.12-2.12a1.5 1.5 0 00-1.061-.44H4.5A2.25 2.25 0 002.25 6v12a2.25 2.25 0 002.25 2.25h15A2.25 2.25 0 0021.75 18V9a2.25 2.25 0 00-2.25-2.25h-5.379a1.5 1.5 0 01-1.06-.44z" /></svg>'
    }
    icons[icon_name.to_sym]&.html_safe
  end
end

