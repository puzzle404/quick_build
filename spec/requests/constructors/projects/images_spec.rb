# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Fotos de la obra", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let!(:stage) { create(:project_stage, project: project, name: "Replanteo") }

  def photo
    Rack::Test::UploadedFile.new(StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 8), "image/png", true,
                                 original_filename: "obra.png")
  end

  before { sign_in(constructor) }

  it "sube una foto vinculada a una etapa" do
    post constructors_project_images_path(project), params: { image: { files: [ photo ], stage_id: stage.id } }

    expect(stage.images.count).to eq(1)
    expect(project.images.count).to eq(0)
    expect(response).to redirect_to(constructors_project_images_path(project))
  end

  it "sin etapa, la foto es de la obra" do
    post constructors_project_images_path(project), params: { image: { files: [ photo ] } }
    expect(project.images.count).to eq(1)
  end

  it "la galería muestra fotos de la obra y de las etapas, con la etapa, y filtra por etapa" do
    create(:image, imageable: project, title: "fachada.png")
    create(:image, imageable: stage, title: "estacas.png")

    get constructors_project_images_path(project)
    expect(response.body).to include("fachada.png", "estacas.png", "Replanteo", 'name="image[stage_id]"')

    get constructors_project_images_path(project, stage: stage.id)
    expect(response.body).to include("estacas.png")
    expect(response.body).not_to include("fachada.png")

    get constructors_project_images_path(project, stage: "none")
    expect(response.body).to include("fachada.png")
    expect(response.body).not_to include("estacas.png")
  end

  it "la galería mobile también deja elegir la etapa y muestra las de etapa" do
    create(:image, imageable: stage, title: "estacas.png")
    cookies["qb_mobile_client"] = "1"
    get constructors_project_images_path(project)

    expect(response.body).to include("estacas.png", 'name="image[stage_id]"')
  end

  it "borra una foto de etapa desde la galería de la obra" do
    image = create(:image, imageable: stage)
    delete constructors_project_image_path(project, image)

    expect(Image.exists?(image.id)).to be(false)
  end

  it "no alcanza fotos de otra obra" do
    foreign = create(:image, imageable: create(:project_stage))
    delete constructors_project_image_path(project, foreign)

    expect(response).to have_http_status(:not_found)
    expect(Image.exists?(foreign.id)).to be(true)
  end

  it "borrar una foto desde el detalle de la etapa ya no explota" do
    image = create(:image, imageable: stage)
    delete constructors_project_stage_image_path(project, stage, image)

    expect(Image.exists?(image.id)).to be(false)
  end

  it "la obra tiene tab Fotos" do
    get constructors_project_path(project)
    expect(response.body).to include(%(href="#{constructors_project_images_path(project)}"), "Fotos")
  end
end
