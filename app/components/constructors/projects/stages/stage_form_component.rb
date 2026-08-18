# frozen_string_literal: true

module Constructors
  module Projects
    module Stages
      # Form de etapa agrupado en bloques: Identidad / Cronograma / Seguimiento
      # / Dependencias. Seguimiento (avance, responsable, presupuesto) sólo
      # aparece al editar: al crear una etapa esos tres valores son 0/vacío y
      # el alta se hace desde un drawer chico.
      #
      # `in_drawer: true` hace que Cancelar cierre el drawer en vez de navegar
      # (la vista de edit lo pasa en la rama turbo_frame).
      class StageFormComponent < ViewComponent::Base
        def initialize(project:, stage:, in_drawer: false, cancel_href: nil)
          @project = project
          @stage = stage
          @in_drawer = in_drawer
          @cancel_href = cancel_href
        end

        private

        attr_reader :project, :stage

        def in_drawer?
          @in_drawer
        end

        # Sólo al editar: al crear, avance/responsable/presupuesto arrancan
        # vacíos y sumarían ruido al drawer de alta.
        def tracking_fields?
          stage.persisted?
        end

        def form_url
          if stage.persisted?
            helpers.constructors_project_stage_path(project, stage)
          else
            helpers.constructors_project_stages_path(project)
          end
        end

        def form_method
          stage.persisted? ? :patch : :post
        end

        def submit_label
          stage.persisted? ? "Actualizar etapa" : "Guardar etapa"
        end

        def cancel_href
          @cancel_href ||
            if stage.persisted?
              helpers.constructors_project_stage_path(project, stage)
            else
              helpers.constructors_project_path(project)
            end
        end

        def delete_href
          helpers.constructors_project_stage_path(project, stage)
        end

        def parent_field_value
          stage.parent_id.presence || options_parent_id
        end

        def options_parent_id
          stage.parent&.id
        end

        # Solo ofrecemos etapas raíz como predecesoras (las sub-etapas no actúan
        # como predecesoras de cronograma). El modelo igual valida mismo-proyecto/ciclo.
        def predecessor_candidates
          @predecessor_candidates ||= project.project_stages
                                             .root
                                             .where.not(id: stage.id.presence)
                                             .order(:position, :name)
                                             .pluck(:name, :id)
        end

        # El bloque de dependencias arranca abierto sólo si hay algo que ver:
        # etapa nueva (ahí se decide el orden), predecesora ya cargada, o error
        # en ese campo. Cerrado por defecto al editar porque el 99% de las
        # etapas no usa predecesora (2 de 192 en la base).
        def dependencies_open?
          !stage.persisted? || stage.predecessor_id.present? ||
            stage.errors[:predecessor].any? || stage.errors[:predecessor_id].any? ||
            stage.errors[:start_date].any?
        end

        # Borde rojo + aria-invalid en el campo culpable: hoy el error dice cuál
        # es la fecha mala y ningún input se resalta.
        def invalid?(attr)
          stage.errors[attr].any?
        end

        def field_style(attr)
          invalid?(attr) ? "border-color:var(--color-bad);" : nil
        end

        def field_opts(attr)
          opts = { class: "qb-input" }
          if invalid?(attr)
            opts[:style] = field_style(attr)
            opts[:'aria-invalid'] = "true"
          end
          opts
        end

        def duration_hint
          return "Sin fechas cargadas." if stage.start_date.blank? || stage.end_date.blank?
          return "El fin es anterior al inicio." if stage.end_date < stage.start_date

          days = (stage.end_date - stage.start_date).to_i + 1
          "#{days} #{days == 1 ? 'día' : 'días'} de duración."
        end

        def progress_value
          stage.progress.to_i
        end

        # El input de plata se tipea en pesos (es-AR) y el controller lo pasa a
        # centavos con Money::ArsParser. Mostramos el valor guardado sin
        # separador de miles para que el round-trip sea idempotente.
        def budget_pesos_value
          cents = stage.budget_cents
          return nil if cents.blank?

          cents % 100 == 0 ? (cents / 100).to_s : format("%.2f", cents / 100.0).tr(".", ",")
        end
      end
    end
  end
end
