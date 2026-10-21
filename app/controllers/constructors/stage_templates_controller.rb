# frozen_string_literal: true

module Constructors
  # Plantillas de etapas guardadas por el constructor: crear (desde una obra),
  # listar y borrar. APLICAR vive en Constructors::Projects::StagesController
  # (#apply_template), que es donde está el contexto de la obra destino.
  #
  # No hay policy propia todavía: las plantillas se scopean por owner
  # (`owned_by`) —una plantilla ajena da 404, no se filtra— y la obra de
  # origen entra por `find_project!` + `authorize :show?`: guardar la WBS de
  # una obra como plantilla es leerla, así que alcanza con verla.
  class StageTemplatesController < Constructors::BaseController
    def index
      @current_qb_section = :projects
      @stage_templates = StageTemplate.owned_by(current_user)
                                      .ordered
                                      .includes(:items, :source_project)
    end

    def create
      find_project!(id: stage_template_params[:project_id])
      authorize @project, :show?

      return redirect_to project_path, alert: "La obra todavía no tiene etapas para guardar." if @project.project_stages.empty?

      result = ::Constructors::Projects::StageTemplateCaptureService.call(
        project: @project,
        owner: current_user,
        name: stage_template_params[:name],
        description: stage_template_params[:description]
      )

      if result.success?
        redirect_to project_path, notice: capture_notice(result)
      else
        redirect_to project_path, alert: capture_alert(result)
      end
    end

    def destroy
      stage_template = StageTemplate.owned_by(current_user).find(params[:id])
      stage_template.destroy

      redirect_to constructors_stage_templates_path, notice: "Plantilla eliminada."
    end

    private

    def project_path
      constructors_project_path(@project)
    end

    def stage_template_params
      params.require(:stage_template).permit(:project_id, :name, :description)
    end

    def capture_notice(result)
      parts = [ "#{result.stages} etapa(s)" ]
      parts << "#{result.sub_stages} subetapa(s)" if result.sub_stages.positive?
      "Plantilla «#{result.template.name}» guardada: #{parts.join(' · ')}."
    end

    def capture_alert(result)
      result.template.errors.full_messages.to_sentence.presence || "No pudimos guardar la plantilla."
    end
  end
end
