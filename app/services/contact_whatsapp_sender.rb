# frozen_string_literal: true

require "net/http"
require "uri"

class ContactWhatsappSender
  TARGET_PHONE = ENV.fetch("CONTACT_WHATSAPP_PHONE", "+5492613831194")

  def initialize(contact_message)
    @contact_message = contact_message
  end

  def deliver
    webhook_url = ENV["CONTACT_WHATSAPP_WEBHOOK_URL"]
    token = ENV["CONTACT_WHATSAPP_TOKEN"]

    unless webhook_url.present?
      Rails.logger.info("Skipping WhatsApp notification: CONTACT_WHATSAPP_WEBHOOK_URL not configured")
      return false
    end

    uri = URI.parse(webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{token}" if token.present?
    request.body = {
      to: TARGET_PHONE,
      message: build_message
    }.to_json

    response = http.request(request)
    response.is_a?(Net::HTTPSuccess)
  rescue StandardError => e
    Rails.logger.error("WhatsApp notification failed: #{e.message}")
    false
  end

  private

  def build_message
    <<~MSG.strip
      Nuevo contacto desde Quick Build:
      Nombre: #{@contact_message.name}
      Empresa: #{@contact_message.company.presence || "No especificada"}
      Teléfono: #{@contact_message.phone.presence || "No especificado"}
      Email: #{@contact_message.email}
      Mensaje: #{@contact_message.message}
    MSG
  end
end
