# frozen_string_literal: true

require "rails_helper"

# Feedback 21/10: en algunos drawers la × estaba arriba a la izquierda y en
# otros a la derecha. En toda la app va a la derecha, como último elemento del
# encabezado (el ‹ de volver, cuando aparece, queda a la izquierda).
RSpec.describe "Encabezado de los drawers", type: :request do
  let(:constructor) { create(:user, :constructor) }
  let(:project) { create(:project, owner: constructor) }
  let(:stage) { create(:project_stage, project: project, name: "Replanteo") }
  let(:frame) { { "Turbo-Frame" => "drawer" } }

  before { sign_in(constructor) }

  def last_header_control
    header = Nokogiri::HTML(body_without_templates).at_css("turbo-frame#drawer .qb-drawer-header")
    expect(header).to be_present, "no se renderizó el drawer"
    header.element_children.last
  end

  def document_on_project
    doc = Document.new(documentable: project)
    doc.file.attach(io: StringIO.new("%PDF-1.4 fake"), filename: "permiso.pdf", content_type: "application/pdf")
    doc.save!
    doc
  end

  {
    "detalle de etapa" => -> { constructors_project_stage_path(project, stage) },
    "editar etapa" => -> { edit_constructors_project_stage_path(project, stage) },
    "nueva etapa" => -> { new_constructors_project_stage_path(project) },
    "detalle de lista de materiales" => -> { constructors_project_material_list_path(project, create(:material_list, project: project, author: constructor)) },
    "visor de la biblioteca" => -> { constructors_library_document_path(document_on_project) },
    "nueva obra" => -> { new_constructors_project_path },
    "editar obra" => -> { edit_constructors_project_path(project) },
    "nuevo gasto" => -> { new_constructors_project_expense_path(project) },
    "nueva nota" => -> { new_constructors_project_note_path(project) },
    "subir fotos" => -> { new_constructors_project_image_path(project) }
  }.each do |name, path|
    it "#{name}: la × es lo último del encabezado (arriba a la derecha)" do
      get instance_exec(&path), headers: frame

      control = last_header_control
      expect(control.name).to eq("button")
      expect(control["class"].to_s.split).to include("qb-drawer-close")
    end
  end
end
