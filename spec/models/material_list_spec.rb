require "rails_helper"

RSpec.describe MaterialList, type: :model do
  subject(:material_list) { build(:material_list) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:author).class_name("User") }
  it { is_expected.to belong_to(:project_stage).optional }
  it { is_expected.to have_many(:material_items).dependent(:destroy) }
  it { is_expected.to have_one(:material_list_publication).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:name) }

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, ready_for_review: 1, approved: 2).backed_by_column_of_type(:integer) }
    it { is_expected.to define_enum_for(:source_type).with_values(manual: 0, pdf_upload: 1, excel_upload: 2).backed_by_column_of_type(:integer) }
  end

  describe "material items" do
    it "permite agregar ítems después de creada" do
      list = create(:material_list, add_default_item: false)

      list.material_items.create!(name: "Arena", quantity: 5, unit: "m3")

      expect(list.material_items.count).to eq(1)
    end
  end

  describe "project stage validation" do
    it "permite asignar etapas del mismo proyecto" do
      project = create(:project)
      stage = create(:project_stage, project: project)
      list = build(:material_list, project: project, project_stage: stage)

      expect(list).to be_valid
    end

    it "rechaza etapas de otro proyecto" do
      project = create(:project)
      other_project = create(:project)
      stage = create(:project_stage, project: other_project)
      list = build(:material_list, project: project, project_stage: stage)

      expect(list).not_to be_valid
      expect(list.errors[:project_stage]).to include("no pertenece a esta obra")
    end
  end

  describe "aprobación" do
    it "registra la fecha al marcar como aprobada" do
      material_list.status = :approved
      material_list.save!

      expect(material_list.approved_at).to be_present
    end

    it "limpia la fecha si vuelve a borrador" do
      material_list.update!(status: :approved)

      material_list.update!(status: :draft)

      expect(material_list.approved_at).to be_nil
    end
  end
end
