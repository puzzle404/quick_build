require 'rails_helper'

RSpec.describe Expense, type: :model do
  describe "validations" do
    subject { build(:expense) }

    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_presence_of(:incurred_on) }
    it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than(0) }
    it { is_expected.to define_enum_for(:category).with_values(labor: 0, materials_misc: 1, rentals: 2, other: 3) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:project_stage).optional }
    it { is_expected.to belong_to(:author).class_name("User") }
  end

  describe "stage/project consistency" do
    let(:project) { create(:project) }

    it "permite stage del mismo proyecto" do
      stage = create(:project_stage, project: project)
      expense = build(:expense, project: project, project_stage: stage)
      expect(expense).to be_valid
    end

    it "rechaza stage de otro proyecto" do
      other_stage = create(:project_stage)
      expense = build(:expense, project: project, project_stage: other_stage)
      expect(expense).not_to be_valid
      expect(expense.errors[:project_stage]).to include(/mismo proyecto/i)
    end
  end

  describe "scopes" do
    let(:project) { create(:project) }
    let(:stage)   { create(:project_stage, project: project) }
    let!(:e1)     { create(:expense, project: project, project_stage: stage, incurred_on: 2.days.ago) }
    let!(:e2)     { create(:expense, project: project, project_stage: nil, incurred_on: 1.day.ago) }

    it ".for_stage devuelve solo expenses con ese stage_id" do
      expect(Expense.for_stage(stage.id)).to contain_exactly(e1)
    end

    it ".for_project devuelve todas las del proyecto" do
      expect(Expense.for_project(project.id)).to contain_exactly(e1, e2)
    end

    it ".recent_first ordena por incurred_on DESC, id DESC" do
      ordered = Expense.recent_first.where(project_id: project.id)
      expect(ordered.first).to eq(e2)  # 1 day ago (más reciente)
      expect(ordered.last).to  eq(e1)  # 2 days ago
    end
  end

  describe "receipt attachment" do
    it "permite adjuntar un recibo" do
      expense = create(:expense, :with_receipt)
      expect(expense.receipt).to be_attached
    end
  end

  describe "receipt content type" do
    it "rechaza recibos que no son JPG, PNG o PDF" do
      expense = build(:expense)
      expense.receipt.attach(
        io: StringIO.new("fake-bytes"),
        filename: "evil.exe",
        content_type: "application/x-msdownload"
      )
      expect(expense).not_to be_valid
      expect(expense.errors[:receipt]).to include(/JPG, PNG o PDF/)
    end

    it "acepta JPG, PNG y PDF" do
      %w[image/jpeg image/png application/pdf].each do |ct|
        expense = build(:expense)
        expense.receipt.attach(io: StringIO.new("bytes"), filename: "ok", content_type: ct)
        expect(expense).to be_valid
      end
    end
  end
end
