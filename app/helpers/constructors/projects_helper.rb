module Constructors::ProjectsHelper
  STATUS_BADGE_CLASSES = {
    'planned' => 'bg-sky-100 text-sky-700 border border-sky-200',
    'in_progress' => 'bg-indigo-100 text-indigo-700 border border-indigo-200',
    'completed' => 'bg-emerald-100 text-emerald-700 border border-emerald-200'
  }.freeze

  def project_status_badge(project)
    status_key = project.status
    classes = STATUS_BADGE_CLASSES.fetch(status_key, 'bg-slate-100 text-slate-700 border border-slate-200')

    tag.span(project.status.humanize, class: "inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold #{classes}")
  end

  def formatted_project_date(date)
    return 'Sin definir' unless date

    l(date, format: :long)
  end
end
