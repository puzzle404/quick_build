require 'rails_helper'

RSpec.describe Projects::ProgressCalculator do
  let(:project) { create(:project) }

  subject(:calc) { described_class.new(project) }

  describe "#percent" do
    it "es 0 cuando el proyecto no tiene stages" do
      expect(calc.percent).to eq(0)
    end

    it "es 0 cuando no hay stages raíz con duración válida" do
      create(:project_stage, project: project, start_date: nil, end_date: nil, progress: 50)
      expect(calc.percent).to eq(0)
    end

    it "ignora sub-stages (solo cuenta raíces)" do
      root = create(:project_stage, project: project,
                    start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 11),
                    progress: 0)
      create(:project_stage, project: project, parent: root,
                    start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 6),
                    progress: 100)
      expect(calc.percent).to eq(0)
    end

    it "calcula promedio ponderado por días" do
      create(:project_stage, project: project,
             start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 11),  # 10 días
             progress: 100)
      create(:project_stage, project: project,
             start_date: Date.new(2026, 2, 1), end_date: Date.new(2026, 2, 11), # 10 días
             progress: 0)
      # (10*1.0 + 10*0.0) / 20 = 0.5 -> 50%
      expect(calc.percent).to eq(50)
    end

    it "redondea a entero" do
      create(:project_stage, project: project,
             start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 4),
             progress: 33)
      expect(calc.percent).to eq(33)
    end
  end
end
