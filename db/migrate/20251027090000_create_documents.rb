class CreateDocuments < ActiveRecord::Migration[7.1]
  def up
    create_table :documents do |t|
      t.references :documentable, polymorphic: true, null: false
      t.timestamps
    end

    migrate_existing_project_documents
  end

  def down
    rollback_to_project_attachments
    drop_table :documents
  end

  private

  def migrate_existing_project_documents
    return unless table_exists?(:active_storage_attachments)

    document_class = Class.new(ApplicationRecord) do
      self.table_name = "documents"
    end
    document_class.reset_column_information

    attachment_scope = ActiveStorage::Attachment.where(record_type: "Project", name: "documents")

    attachment_scope.find_each do |attachment|
      document = document_class.create!(
        documentable_type: attachment.record_type,
        documentable_id: attachment.record_id,
        created_at: attachment.created_at,
        updated_at: attachment.updated_at
      )

      attachment.update!(
        record_type: "Document",
        record_id: document.id,
        name: "file"
      )
    end
  end

  def rollback_to_project_attachments
    return unless table_exists?(:active_storage_attachments)

    document_class = Class.new(ApplicationRecord) do
      self.table_name = "documents"
    end
    document_class.reset_column_information

    attachment_scope = ActiveStorage::Attachment.where(record_type: "Document", name: "file")

    attachment_scope.find_each do |attachment|
      document = document_class.find_by(id: attachment.record_id)
      next unless document

      attachment.update!(
        record_type: document.documentable_type,
        record_id: document.documentable_id,
        name: "documents"
      )

      document.destroy!
    end
  end
end
