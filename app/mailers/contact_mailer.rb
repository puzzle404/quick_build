# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  CONTACT_EMAIL = ENV.fetch("CONTACT_FORM_EMAIL", "no-reply@test-68zxl2708om4j905.mlsender.net")
  default to: CONTACT_EMAIL, from: ENV.fetch("CONTACT_FORM_SENDER", "no-reply@quickbuild.com"), template_path: "mailer/contact"

  def new_request
    attributes = params[:contact_message_attributes] || {}
    @contact_message = ContactMessage.new(attributes)
    mail(
      subject: "Nuevo contacto desde Quick Build",
      reply_to: @contact_message.email
    )
  end
end
