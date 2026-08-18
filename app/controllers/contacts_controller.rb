# frozen_string_literal: true

class ContactsController < ApplicationController
  allow_unauthenticated_access
  layout "marketing"

  before_action :resume_session

  def create
    @contact_message = ContactMessage.new(contact_message_params)

    if @contact_message.valid?
      ContactMailer.with(contact_message_attributes: @contact_message.attributes.to_h).new_request.deliver_later
      ContactWhatsappJob.perform_later(@contact_message.attributes.to_h)

      redirect_to root_path(anchor: "contacto"), notice: "¡Gracias! Recibimos tu mensaje y nos pondremos en contacto a la brevedad."
    else
      render "home/index", status: :unprocessable_entity
    end
  end

  private

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :phone, :company, :message)
  end
end
