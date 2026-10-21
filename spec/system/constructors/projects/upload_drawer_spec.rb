# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Drawer de subida de fotos", type: :system, js: true do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }

  it "Subir está bloqueado hasta elegir archivos, que se listan antes de subir" do
    create(:project_stage, project: project, name: "Replanteo")
    file = Tempfile.new([ "fachada", ".png" ])
    file.binmode
    file.write("\x89PNG\r\n\x1a\n" + "\x00" * 8)
    file.flush

    sign_in_user(constructor)
    visit constructors_project_images_path(project)
    click_link "Subir fotos"

    submit = find("button[data-qb-file-submit]", wait: 5)
    expect(submit).to be_disabled

    attach_file "image[files][]", file.path, make_visible: true

    expect(page).to have_css(".qb-file-field-list li", text: File.basename(file.path), wait: 5)
    expect(submit).not_to be_disabled
    expect(page).to have_select("image[stage_id]", with_options: [ "Replanteo" ])
  ensure
    file&.close!
  end
end
