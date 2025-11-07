# frozen_string_literal: true

module Constructors
  class DashboardService
    def initialize(user)
      @user = user
    end

    def self.perform(user)
      new(user).perform
    end

    def perform
      {
        metrics: metrics_data,
        recent_activity: recent_activity_entries,
        upcoming_stages: upcoming_stages_list,
        recent_documents: recent_documents_list,
        evolution: evolution_data
      }
    end

    private

    attr_reader :user

    def projects
      @projects ||= user.owned_projects
    end

    def project_ids
      @project_ids ||= projects.pluck(:id)
    end

    def metrics_data
      lists = MaterialList.where(project_id: project_ids)
      items = MaterialItem.joins(:material_list).where(material_lists: { project_id: project_ids })

      total_estimated_cents = items.to_a.sum { |i| i.total_estimated_cost_cents.to_i }

      {
        total_projects: projects.count,
        planned_projects: projects.planned.count,
        in_progress_projects: projects.in_progress.count,
        completed_projects: projects.completed.count,
        material_lists: lists.count,
        material_items: items.count,
        total_estimated_cents: total_estimated_cents
      }
    end

    def recent_activity_entries
      entries = []
      projects.includes(:members).limit(25).each do |project|
        ::Projects::ActivitiesService.perform(project).each do |entry|
          entries << entry.merge(title: "#{project.name} — #{entry[:title]}")
        end
      end
      entries.sort_by { |e| e[:timestamp] || Time.zone.at(0) }.reverse.first(6)
    end

    def upcoming_stages_list
      ProjectStage.where(project_id: project_ids)
                  .where.not(start_date: nil)
                  .order(start_date: :asc)
                  .limit(6)
                  .includes(:project)
    end

    def recent_documents_list
      return [] if project_ids.empty?

      document_scope = Document
        .where(documentable_type: "Project", documentable_id: project_ids)

      stage_ids = ProjectStage.where(project_id: project_ids).pluck(:id)

      if stage_ids.any?
        document_scope = document_scope.or(
          Document.where(documentable_type: "ProjectStage", documentable_id: stage_ids)
        )
      end

      document_scope
        .includes(:documentable, file_attachment: :blob)
        .order(created_at: :desc)
        .limit(6)
    end

    # Evolución mensual (últimos 6 meses) con métricas relevantes
    def evolution_data
      months = (0..5).map { |i| (Date.current.beginning_of_month - (5 - i).months) }
      range_start = months.first
      range_end   = months.last.end_of_month

      month_key = ->(dt) { dt.strftime('%Y-%m') }
      labels = months.map { |d| I18n.l(d, format: '%b %Y') }

      # Inicializar hash con ceros
      zero_hash = months.map { |d| [month_key.call(d), 0] }.to_h

      # Etapas
      stages_scope = ProjectStage.where(project_id: project_ids)
      started = zero_hash.dup
      completed = zero_hash.dup
      stages_scope.where(start_date: range_start..range_end).pluck(:start_date).each do |sd|
        started[month_key.call(sd)] += 1 if sd
      end
      stages_scope.where(end_date: range_start..range_end).pluck(:end_date).each do |ed|
        completed[month_key.call(ed)] += 1 if ed
      end

      # Asistencias
      att_scope = PersonAttendance.joins(:project_person).where(project_people: { project_id: project_ids })
      attendances = zero_hash.dup
      att_scope.where(occurred_at: range_start..range_end).pluck(:occurred_at).each do |ts|
        attendances[month_key.call(ts.to_date)] += 1 if ts
      end

      # Costo estimado cargado (MaterialItem)
      mi_scope = MaterialItem.joins(:material_list).where(material_lists: { project_id: project_ids })
      estimated = zero_hash.dup
      mi_scope.where(created_at: range_start..range_end).pluck(:created_at, :estimated_cost_cents, :quantity).each do |ts, est_cents, qty|
        line_total_cents = (qty.to_f * est_cents.to_i).round
        estimated[month_key.call(ts.to_date)] += line_total_cents
      end

      # Armado de series en orden de months
      def values_for(months, hash, key_fn)
        months.map { |d| hash[key_fn.call(d)] }
      end

      s_started   = values_for(months, started, month_key)
      s_completed = values_for(months, completed, month_key)
      s_att       = values_for(months, attendances, month_key)
      s_est       = values_for(months, estimated, month_key)

      # Resumen mes actual vs anterior
      idx_curr = months.size - 1
      idx_prev = months.size - 2
      curr = {
        started: s_started[idx_curr],
        completed: s_completed[idx_curr],
        attendances: s_att[idx_curr],
        estimated_cents: s_est[idx_curr]
      }
      prev = {
        started: s_started[idx_prev],
        completed: s_completed[idx_prev],
        attendances: s_att[idx_prev],
        estimated_cents: s_est[idx_prev]
      }

      pct = ->(c, p) { p.to_i == 0 ? nil : (((c.to_f - p.to_f) / p.to_f) * 100.0).round(1) }

      {
        labels: labels,
        months: months,
        series: {
          stages_started:   { label: 'Etapas iniciadas', values: s_started },
          stages_completed: { label: 'Etapas finalizadas', values: s_completed },
          attendances:      { label: 'Asistencias registradas', values: s_att },
          estimated_cents:  { label: 'Costo estimado cargado (ARS)', values: s_est }
        },
        summary: {
          current_label: labels.last,
          started:   { current: curr[:started], previous: prev[:started], delta_pct: pct.call(curr[:started], prev[:started]) },
          completed: { current: curr[:completed], previous: prev[:completed], delta_pct: pct.call(curr[:completed], prev[:completed]) },
          attendances: { current: curr[:attendances], previous: prev[:attendances], delta_pct: pct.call(curr[:attendances], prev[:attendances]) },
          estimated_cents: { current: curr[:estimated_cents], previous: prev[:estimated_cents], delta_pct: pct.call(curr[:estimated_cents], prev[:estimated_cents]) }
        }
      }
    end
  end
end
