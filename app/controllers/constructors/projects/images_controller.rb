class Constructors::Projects::ImagesController < Constructors::BaseController
  before_action :set_project

  def index
    authorize @project, :show?
    @images = @project.images.includes(file_attachment: :blob).order(created_at: :desc)
  end

  def create
    authorize @project, :update?

    files = Array.wrap(image_params[:files]).compact_blank
    if files.empty?
      redirect_to constructors_project_images_path(@project), alert: "Seleccioná al menos una imagen." and return
    end

    created = 0
    ActiveRecord::Base.transaction do
      files.each do |uploaded|
        image = @project.images.build
        image.file.attach(uploaded)
        image.title ||= image.file_filename.to_s
        image.save!
        created += 1
      end
    end

    redirect_to constructors_project_images_path(@project), notice: created > 1 ? "#{created} imágenes cargadas." : "Imagen cargada."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to constructors_project_images_path(@project), alert: "No pudimos cargar la imagen: #{e.record.errors.full_messages.to_sentence}."
  end

  def destroy
    authorize @project, :update?
    image = @project.images.find(params[:id])
    image.destroy
    redirect_to constructors_project_images_path(@project), notice: "Imagen eliminada."
  end

  private

  def set_project
    @project = current_user.owned_projects.find(params[:project_id])
  end

  def image_params
    params.fetch(:image, {}).permit(:title, :description, files: [])
  end
end

