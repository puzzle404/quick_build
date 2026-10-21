require 'rails_helper'

RSpec.describe Constructors::Projects::DocumentSearchService do
  include ActiveSupport::Testing::TimeHelpers

  describe '#results' do
    let(:project) { create(:project) }

    def build_document(project, filename, captured_at)
      travel_to captured_at do
        document = project.documents.build
        document.file.attach(
          io: StringIO.new('PDF'),
          filename: filename,
          content_type: 'application/pdf'
        )
        document.save!
        document
      end
    end

    it 'filters by filename matches' do
      matching = build_document(project, 'planos-obra.pdf', Time.zone.local(2024, 1, 1, 10))
      build_document(project, 'contrato.pdf', Time.zone.local(2024, 1, 5, 12))

      results = described_class.new(project: project, query: 'planos').results

      expect(results).to contain_exactly(matching)
    end

    it 'applies upload date range filters' do
      recent = build_document(project, 'avance.pdf', Time.zone.local(2024, 2, 15, 9))
      build_document(project, 'historial.pdf', Time.zone.local(2023, 6, 10, 9))

      results = described_class.new(project: project, from_date: '2024-02-01').results

      expect(results).to contain_exactly(recent)
    end
  end
end
