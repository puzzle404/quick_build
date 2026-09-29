# frozen_string_literal: true

class ContactWhatsappJob < ApplicationJob
  queue_as :default

  def perform(contact_attributes)
    contact_message = ContactMessage.new(contact_attributes)
    ContactWhatsappSender.new(contact_message).deliver
  end
end
