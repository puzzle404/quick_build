# frozen_string_literal: true

# Compact recent documents list — kind badge + name + uploader + date.
class Constructors::Projects::Overview::RecentDocsComponent < ViewComponent::Base
  def initialize(documents:)
    @documents = Array(documents)
  end

  attr_reader :documents

  def kind_for(doc)
    return doc.try(:kind).to_s.upcase if doc.try(:kind).present?
    return doc.file.blob.content_type.split('/').last.upcase[0, 3] if doc.respond_to?(:file) && doc.file.attached?
    'DOC'
  rescue StandardError
    'DOC'
  end

  def name_for(doc)
    return doc.title if doc.try(:title).present?
    return doc.file.filename.to_s if doc.respond_to?(:file) && doc.file.attached?
    'Documento'
  rescue StandardError
    'Documento'
  end

  def uploader_for(doc)
    u = doc.try(:user) || doc.try(:uploader)
    u ? (u.try(:email)&.split('@')&.first&.titleize || u.to_s) : 'Sistema'
  end

  def at_for(doc)
    helpers.qb_fmt_date_short(doc.try(:created_at) || doc.try(:updated_at))
  end
end
