class Constructors::Projects::DocumentsController < Constructors::BaseController
  before_action :set_project

  def index
    authorize @project, :show?
    @documents = @project.documents.includes(file_attachment: :blob).order(created_at: :desc)
  end

  def create
    authorize @project, :update?

    files = Array.wrap(document_params[:files]).compact_blank

    if files.empty?
      redirect_to constructors_project_documents_path(@project), alert: "Debes seleccionar al menos un archivo." and return
    end

    created_count = 0

    ActiveRecord::Base.transaction do
      files.each do |file|
        document = @project.documents.build
        document.file.attach(file)
        document.save!
        created_count += 1
      end
    end

    message = created_count > 1 ? "#{created_count} documentos subidos correctamente." : "Documento subido correctamente."
    redirect_to constructors_project_documents_path(@project), notice: message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to constructors_project_documents_path(@project), alert: "No pudimos adjuntar el documento: #{e.record.errors.full_messages.to_sentence}."
  end

  def destroy
    authorize @project, :update?
    document = @project.documents.find(params[:id])
    document.destroy

    redirect_to constructors_project_documents_path(@project), notice: "Documento eliminado."
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end

  def document_params
    params.fetch(:document, {}).permit(files: [])
  end
end
