class Projects::ActivitiesService
  def initialize(project)
    @project = project
  end

  def self.perform(project)
    new(project).perform
  end

  def perform
    @activity_entries ||= begin
      entries = []
      entries << build_entry('Proyecto creado', @project.created_at, "#{@project.owner.email} creó la obra.") if @project.created_at
      if @project.updated_at && @project.updated_at != @project.created_at
        entries << build_entry('Información actualizada', @project.updated_at, 'Se registraron cambios en los datos del proyecto.')
      end
      @project.members.limit(3).each do |membership|
        next unless membership.created_at

        entries << build_entry('Nuevo miembro asignado', membership.created_at,
                               "#{membership.email} se unió como #{membership.role.humanize.downcase}.")
      end
      entries.sort_by { |entry| entry[:timestamp] || Time.zone.now }.reverse
    end
  end

  private

  def build_entry(title, timestamp, description)
    { title:, timestamp:, description: }
  end
end