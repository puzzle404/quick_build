module Constructors
  module Projects
    # Aplica una plantilla de etapas sobre una obra.
    #
    # Dos fuentes posibles:
    #   * `template: nil`            → la plantilla base del sistema (TEMPLATE).
    #   * `template: <StageTemplate>` → una plantilla guardada por el usuario.
    #
    # Idempotente: busca por nombre dentro del scope correspondiente (raíz o
    # hijos de una etapa) y sólo crea lo que falta. Las etapas que ya existen
    # NO se pisan — ni fechas ni presupuesto; a lo sumo se les completa la
    # descripción si estaba vacía. Es el comportamiento histórico y el que
    # espera stages#apply_template.
    #
    # Fechas: la plantilla guarda offsets relativos, así que se materializan
    # desde `project.start_date`. Si la obra no tiene fecha de inicio (o el
    # ítem no trae offset) la etapa se crea sin fechas en vez de bloquear.
    #
    # Presupuestos: opt-in (`apply_budgets`, apagado por defecto). Si el ítem
    # trae porcentaje y la obra destino tiene presupuesto, manda el porcentaje
    # (la plantilla escala a la obra); si no, se usa el monto absoluto.
    class StageTemplateService
      TEMPLATE = [
        {
          name: "Proyecto y gestión",
          description: "Definición técnica y administrativa del proyecto base.",
          sub_stages: [
            { name: "Estudios preliminares" },
            { name: "Ante proyecto" },
            { name: "Proyecto (presentación municipal)" },
            { name: "Documentación y permisos" },
            { name: "3D y visualizaciones" },
            { name: "Presentación conforme a obra" }
          ]
        },
        {
          name: "Dirección de obra",
          description: "Coordinación diaria, planos ejecutivos e inspecciones en sitio.",
          sub_stages: [
            { name: "Plan de trabajo" },
            { name: "Planos ejecutivos por rubros" },
            { name: "Inspecciones" }
          ]
        },
        {
          name: "Administración",
          description: "Gestión financiera y control de contratistas involucrados.",
          sub_stages: [
            { name: "Materiales" },
            { name: "Mano de obra" }
          ]
        }
      ].freeze

      Result = Struct.new(:created, :skipped, :sub_created, :sub_skipped, keyword_init: true)

      # Nodo normalizado: unifica la constante hardcodeada y los
      # StageTemplateItem persistidos para que `call` tenga una sola forma.
      Node = Struct.new(:name, :description, :start_offset_days, :duration_days,
                        :budget_cents, :budget_pct, :children, keyword_init: true)

      def self.call(project, template: nil, apply_dates: true, apply_budgets: false)
        new(project, template: template, apply_dates: apply_dates, apply_budgets: apply_budgets).call
      end

      def initialize(project, template: nil, apply_dates: true, apply_budgets: false)
        @project = project
        @template = template
        @apply_dates = apply_dates
        @apply_budgets = apply_budgets
      end

      def call
        created = 0
        skipped = 0
        sub_created = 0
        sub_skipped = 0

        ProjectStage.transaction do
          root_position = next_position(nil)

          nodes.each do |node|
            stage, stage_is_new = build_stage(node, parent: nil, position: root_position)
            if stage_is_new
              created += 1
              root_position += 1
            else
              skipped += 1
            end

            stage.save!

            child_position = next_position(stage)
            node.children.each do |child_node|
              sub_stage, sub_is_new = build_stage(child_node, parent: stage, position: child_position)
              if sub_is_new
                sub_created += 1
                child_position += 1
              else
                sub_skipped += 1
              end

              sub_stage.save!
            end
          end
        end

        Result.new(created:, skipped:, sub_created:, sub_skipped:)
      end

      private

      attr_reader :project, :template, :apply_dates, :apply_budgets

      def stage_scope
        @stage_scope ||= project.project_stages
      end

      def nodes
        @nodes ||= template.present? ? nodes_from_template : nodes_from_constant
      end

      def nodes_from_constant
        TEMPLATE.map do |config|
          children = config.fetch(:sub_stages, []).map do |sub|
            Node.new(name: sub[:name], description: sub[:description], children: [])
          end
          Node.new(name: config[:name], description: config[:description], children:)
        end
      end

      def nodes_from_template
        items = template.items.to_a.sort_by { |item| [ item.position.to_i, item.id.to_i ] }
        roots = items.select { |item| item.parent_id.nil? }

        roots.map do |root|
          children = items.select { |item| item.parent_id == root.id }
          node_from_item(root, children.map { |child| node_from_item(child, []) })
        end
      end

      def node_from_item(item, children)
        Node.new(
          name: item.name,
          description: item.description,
          start_offset_days: item.start_offset_days,
          duration_days: item.duration_days,
          budget_cents: item.budget_cents,
          budget_pct: item.budget_pct,
          children:
        )
      end

      # Las etapas nuevas se numeran a continuación de las que ya existen, así
      # el orden del listado queda determinístico y la plantilla no se
      # intercala con lo que el usuario ya había cargado.
      def next_position(parent)
        stage_scope.where(parent_id: parent&.id).maximum(:position).to_i + 1
      end

      def build_stage(node, parent:, position:)
        scope = parent.present? ? stage_scope.where(parent: parent) : stage_scope.root
        stage = scope.find_or_initialize_by(name: node.name)
        stage_is_new = stage.new_record?

        stage.description = node.description if stage.description.blank? && node.description.present?

        if stage_is_new
          stage.position = position
          assign_dates(stage, node)
          assign_budget(stage, node)
        end

        [ stage, stage_is_new ]
      end

      def assign_dates(stage, node)
        return unless apply_dates
        return if project.start_date.blank? || node.start_offset_days.nil?

        stage.start_date = project.start_date + node.start_offset_days
        return if node.duration_days.nil?

        stage.end_date = stage.start_date + node.duration_days
      end

      def assign_budget(stage, node)
        return unless apply_budgets

        cents = resolved_budget_cents(node)
        stage.budget_cents = cents if cents.present?
      end

      def resolved_budget_cents(node)
        total = project.budget_cents.to_i
        return (total * node.budget_pct.to_f / 100.0).round if node.budget_pct.present? && total.positive?

        node.budget_cents
      end
    end
  end
end
