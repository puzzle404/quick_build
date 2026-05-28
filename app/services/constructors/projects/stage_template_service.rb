module Constructors
  module Projects
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

      def self.call(project)
        new(project).call
      end

      def initialize(project)
        @project = project
      end

      def call
        created = 0
        skipped = 0
        sub_created = 0
        sub_skipped = 0

        ProjectStage.transaction do
          TEMPLATE.each do |stage_config|
            stage, created_flag = find_or_build_stage(stage_config)
            created += 1 if created_flag
            skipped += 1 unless created_flag

            stage.save!

            stage_config.fetch(:sub_stages, []).each do |sub_stage_config|
              sub_stage, sub_created_flag = find_or_build_sub_stage(stage, sub_stage_config)
              sub_created += 1 if sub_created_flag
              sub_skipped += 1 unless sub_created_flag

              sub_stage.save!
            end
          end
        end

        Result.new(created:, skipped:, sub_created:, sub_skipped:)
      end

      private

      attr_reader :project

      def stage_scope
        @stage_scope ||= project.project_stages
      end

      def find_or_build_stage(config)
        stage = stage_scope.root.find_or_initialize_by(name: config[:name])
        stage.description = config[:description] if stage.description.blank? && config[:description].present?
        [stage, stage.new_record?]
      end

      def find_or_build_sub_stage(parent_stage, config)
        sub_stage = stage_scope.where(parent: parent_stage).find_or_initialize_by(name: config[:name])
        sub_stage.description = config[:description] if sub_stage.description.blank? && config[:description].present?
        [sub_stage, sub_stage.new_record?]
      end
    end
  end
end
