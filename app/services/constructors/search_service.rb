# frozen_string_literal: true

# Cross-model fuzzy search for the QB OS command palette.
# Returns a hash grouped by entity kind so the cmd palette can render section
# headers without further client-side bucketing.
#
# Searches scoped to the constructor's owned_projects (projects, stages,
# documents, material_lists) plus their team members. Read-only.
module Constructors
  class SearchService
    LIMIT_PER_GROUP = 6

    # Always-on actions surfaced even when the query is empty. Each entry
    # responds to #to_h producing { label, hint, url, icon }.
    def initialize(user:, query:)
      @user = user
      @query = query.to_s.strip
    end

    def call
      return empty_payload if @user.nil?

      project_ids = owned_project_ids
      {
        projects:   project_results(project_ids),
        people:     people_results(project_ids),
        stages:     stage_results(project_ids),
        documents:  document_results(project_ids),
        material_lists: material_list_results(project_ids),
        actions:    action_results
      }
    end

    private

    def empty_payload
      { projects: [], people: [], stages: [], documents: [], material_lists: [], actions: action_results }
    end

    def owned_project_ids
      @user.owned_projects.pluck(:id)
    end

    # Projects · pg_search on name+location, plus a fallback ILIKE for code
    # (we synthesize codes as PRJ-NNN, not stored as a column).
    def project_results(project_ids)
      return [] if project_ids.empty?
      scope = @user.owned_projects.order(updated_at: :desc)
      if @query.present?
        searched = scope.search_text(@query) rescue scope.where('LOWER(name) LIKE ?', "%#{@query.downcase}%")
        # Code match: query like "PRJ-042" or "42" → match by id zero-padded
        if (m = @query.match(/\A(?:prj-?)?(\d+)\z/i))
          id_match = scope.where('id::text LIKE ?', "%#{m[1]}%")
          searched = scope.where(id: searched.pluck(:id) | id_match.pluck(:id))
        end
      else
        searched = scope
      end
      searched.includes(:owner).limit(LIMIT_PER_GROUP).map { |p| project_to_h(p) }
    end

    def project_to_h(p)
      decorated = p.is_a?(ProjectDecorator) ? p : ProjectDecorator.new(p)
      {
        kind:  'project',
        id:    p.id,
        label: p.name.to_s,
        hint:  "Proyecto · #{decorated.code}",
        url:   Rails.application.routes.url_helpers.constructors_project_path(p),
        icon:  'projects'
      }
    end

    def people_results(project_ids)
      return [] if project_ids.empty? || @query.blank?
      ProjectPerson.where(project_id: project_ids)
                   .where('LOWER(full_name) LIKE :q OR LOWER(role_title) LIKE :q', q: "%#{@query.downcase}%")
                   .includes(:project)
                   .limit(LIMIT_PER_GROUP)
                   .map { |pp| person_to_h(pp) }
    end

    def person_to_h(pp)
      {
        kind:  'person',
        id:    pp.id,
        label: pp.full_name,
        hint:  "Persona · #{pp.project.name.to_s.split('·').first&.strip}",
        url:   Rails.application.routes.url_helpers.constructors_project_person_path(pp.project, pp),
        icon:  'people'
      }
    end

    def stage_results(project_ids)
      return [] if project_ids.empty? || @query.blank?
      ProjectStage.where(project_id: project_ids)
                  .where('LOWER(name) LIKE ?', "%#{@query.downcase}%")
                  .includes(:project)
                  .limit(LIMIT_PER_GROUP)
                  .map { |s| stage_to_h(s) }
    end

    def stage_to_h(s)
      project_short = s.project.name.to_s.split('·').first&.strip
      {
        kind:  'stage',
        id:    s.id,
        label: s.name,
        hint:  "Etapa · #{project_short}",
        url:   Rails.application.routes.url_helpers.constructors_project_stage_path(s.project, s),
        icon:  'stages'
      }
    end

    def document_results(project_ids)
      return [] if project_ids.empty? || @query.blank?
      Document.joins('LEFT JOIN active_storage_attachments asa ON asa.record_id = documents.id AND asa.record_type = \'Document\'')
              .joins('LEFT JOIN active_storage_blobs asb ON asb.id = asa.blob_id')
              .where(documentable_type: 'Project', documentable_id: project_ids)
              .where('LOWER(asb.filename) LIKE ?', "%#{@query.downcase}%")
              .limit(LIMIT_PER_GROUP)
              .map { |d| document_to_h(d) }
    rescue StandardError
      []
    end

    def document_to_h(d)
      project = d.documentable_type == 'Project' ? Project.find_by(id: d.documentable_id) : nil
      filename = d.respond_to?(:file) && d.file.attached? ? d.file.filename.to_s : 'Documento'
      {
        kind:  'document',
        id:    d.id,
        label: filename,
        hint:  project ? "Documento · #{project.name.to_s.split('·').first&.strip}" : 'Documento',
        url:   project ? Rails.application.routes.url_helpers.constructors_project_documents_path(project) : '#',
        icon:  'docs'
      }
    end

    def material_list_results(project_ids)
      return [] if project_ids.empty? || @query.blank?
      MaterialList.where(project_id: project_ids)
                  .where('LOWER(name) LIKE ?', "%#{@query.downcase}%")
                  .includes(:project)
                  .limit(LIMIT_PER_GROUP)
                  .map { |ml| material_list_to_h(ml) }
    end

    def material_list_to_h(ml)
      {
        kind:  'material_list',
        id:    ml.id,
        label: ml.name,
        hint:  "Lista de materiales · #{ml.project.name.to_s.split('·').first&.strip}",
        url:   Rails.application.routes.url_helpers.constructors_project_material_lists_path(ml.project),
        icon:  'materials'
      }
    end

    # Shortcut actions — surfaced always; filtered client-side by label.
    def action_results
      [
        { kind: 'action', label: 'Crear nuevo proyecto',     hint: 'Acción',      url: Rails.application.routes.url_helpers.new_constructors_project_path, icon: 'plus' },
        { kind: 'action', label: 'Ir a Personas',            hint: 'Navegación',  url: Rails.application.routes.url_helpers.constructors_people_path,      icon: 'people' },
        { kind: 'action', label: 'Ir a Proyectos',           hint: 'Navegación',  url: Rails.application.routes.url_helpers.constructors_projects_path,    icon: 'projects' },
        { kind: 'action', label: 'Ir a Dashboard',           hint: 'Navegación',  url: Rails.application.routes.url_helpers.constructors_root_path,        icon: 'dashboard' }
      ].select { |a| @query.blank? || a[:label].downcase.include?(@query.downcase) }
    end
  end
end
