module Projects
  class ProgressCalculator
    def initialize(project)
      @project = project
    end

    def percent
      total_weight = 0
      weighted_sum = 0.0

      root_stages.each do |stage|
        days = duration_days(stage)
        next if days <= 0

        total_weight += days
        weighted_sum += days * (stage.progress.to_i / 100.0)
      end

      return 0 if total_weight.zero?

      ((weighted_sum / total_weight) * 100).round
    end

    private

    # Si el caller ya cargó las etapas (projects#show las lee una sola vez para
    # toda la pantalla) filtramos en Ruby en vez de repetir el SELECT.
    def root_stages
      stages = @project.project_stages
      return stages.to_a.select { |stage| stage.parent_id.nil? } if stages.loaded?

      stages.root
    end

    def duration_days(stage)
      return 0 if stage.start_date.blank? || stage.end_date.blank?

      (stage.end_date - stage.start_date).to_i
    end
  end
end
