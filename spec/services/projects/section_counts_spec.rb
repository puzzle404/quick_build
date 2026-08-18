# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::SectionCounts do
  let(:project) { create(:project) }

  subject(:counts) { described_class.new(project) }

  it "arranca en cero para una obra vacía" do
    expect(counts.to_h).to eq(stages: 0, materials: 0, expenses: 0, blueprints: 0, team: 0, docs: 0)
  end

  it "cuenta lo mismo que los `.count` de cada asociación" do
    root = create(:project_stage, project: project)
    create(:project_stage, project: project, parent: root) # sub-etapa: NO suma
    create_list(:material_list, 2, project: project)
    create(:expense, project: project)
    create(:blueprint, project: project)
    create_list(:project_person, 3, project: project)
    Document.insert_all([ { documentable_type: "Project", documentable_id: project.id,
                            created_at: Time.current, updated_at: Time.current } ])

    expect(counts.to_h).to eq(
      stages: project.project_stages.where(parent_id: nil).count,
      materials: project.material_lists.count,
      expenses: project.expenses.count,
      blueprints: project.blueprints.count,
      team: project.project_people.count,
      docs: project.documents.count
    )
  end

  it "en la pestaña Etapas cuenta sólo las raíces" do
    root = create(:project_stage, project: project)
    create_list(:project_stage, 3, project: project, parent: root)

    expect(counts[:stages]).to eq(1)
  end

  it "no cuenta datos de otra obra" do
    create(:material_list, project: create(:project))
    create(:expense, project: create(:project))

    expect(counts[:materials]).to eq(0)
    expect(counts[:expenses]).to eq(0)
  end

  it "resuelve los seis contadores en UNA sola query" do
    create(:project_stage, project: project)
    create(:material_list, project: project)

    expect(count_queries { counts.to_h }).to eq(1)
  end
end
