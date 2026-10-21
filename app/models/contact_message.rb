# frozen_string_literal: true

class ContactMessage
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :phone, :string
  attribute :company, :string
  attribute :message, :string

  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def summary
    [
      "Nombre: #{name}",
      ("Empresa: #{company}" if company.present?),
      ("Teléfono: #{phone}" if phone.present?),
      "Email: #{email}",
      "Mensaje: #{message}"
    ].compact.join(" | ")
  end
end
