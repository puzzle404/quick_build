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
        recent_documents: recent_documents_list
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
  end
end
