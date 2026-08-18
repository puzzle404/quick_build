module Constructors
  module Projects
    # Guarda la WBS de una obra como plantilla reutilizable.
    #
    # Convierte las fechas absolutas de cada etapa en offsets relativos al
    # inicio de la obra (`start_offset_days`) + duración (`duration_days`), de
    # modo que la plantilla se pueda aplicar a obras que arrancan en otra
    # fecha. Si la obra no tiene fecha de inicio, la plantilla queda sin
    # cronograma (nombres y presupuestos igual se guardan).
    #
    # Presupuestos: se guardan el monto y, cuando la obra tiene presupuesto
    # total, también el porcentaje que representa. Aplicarlos después es
    # opt-in en StageTemplateService.
    #
    # NUNCA copia progreso, gasto, responsable, predecesora ni asociaciones
    # (listas de materiales, documentos, imágenes, gastos, notas): una
    # plantilla es un plan, no un estado. Mismo criterio que stages#duplicate.
    class StageTemplateCaptureService
      # Techo de la columna decimal(5,2) de budget_pct.
      MAX_BUDGET_PCT = 999.99

      Result = Struct.new(:template, :stages, :sub_stages, keyword_init: true) do
        def success?
          template.persisted?
        end
      end

      def self.call(project:, owner:, name:, description: nil, include_budgets: true)
        new(project:, owner:, name:, description:, include_budgets:).call
      end

      def initialize(project:, owner:, name:, description: nil, include_budgets: true)
        @project = project
        @owner = owner
        @name = name
        @description = description
        @include_budgets = include_budgets
      end

      def call
        template = build_template
        stages = 0
        sub_stages = 0

        StageTemplate.transaction do
          # Nombre repetido o vacío: se corta acá y el controller muestra los
          # errores del record sin persistir nada.
          raise ActiveRecord::Rollback unless template.save

          root_stages.each_with_index do |stage, index|
            item = template.items.create!(item_attributes(stage).merge(position: index + 1))
            stages += 1

            sub_stages_of(stage).each_with_index do |sub_stage, sub_index|
              template.items.create!(item_attributes(sub_stage).merge(parent: item, position: sub_index + 1))
              sub_stages += 1
            end
          end
        end

        Result.new(template:, stages:, sub_stages:)
      end

      private

      attr_reader :project, :owner, :name, :description, :include_budgets

      def build_template
        StageTemplate.new(
          owner_id: owner&.id,
          name: name.to_s.strip,
          description: description.presence,
          source_project_id: project.id
        )
      end

      def root_stages
        @root_stages ||= project.project_stages.root.ordered.includes(:sub_stages).to_a
      end

      def sub_stages_of(stage)
        stage.sub_stages.sort_by { |sub| [ sub.position.to_i, sub.name.to_s ] }
      end

      def item_attributes(stage)
        {
          name: stage.name,
          description: stage.description,
          start_offset_days: offset_days_for(stage),
          duration_days: duration_days_for(stage),
          budget_cents: include_budgets ? stage.budget_cents : nil,
          budget_pct: include_budgets ? budget_pct_for(stage) : nil
        }
      end

      def offset_days_for(stage)
        return nil if project.start_date.blank? || stage.start_date.blank?

        (stage.start_date - project.start_date).to_i
      end

      def duration_days_for(stage)
        return nil if stage.start_date.blank? || stage.end_date.blank?

        delta = (stage.end_date - stage.start_date).to_i
        delta.negative? ? nil : delta
      end

      # El porcentaje permite escalar la plantilla a obras con otro
      # presupuesto. Se recorta al techo de la columna para no romper en PG
      # cuando una etapa tiene más presupuesto que la obra entera.
      def budget_pct_for(stage)
        total = project.budget_cents.to_i
        return nil unless total.positive?
        return nil unless stage.budget_cents.to_i.positive?

        pct = (stage.budget_cents.to_f / total * 100).round(2)
        [ pct, MAX_BUDGET_PCT ].min
      end
    end
  end
end
