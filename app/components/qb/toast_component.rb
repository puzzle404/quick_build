# frozen_string_literal: true

# Un toast (ver Qb::ToastStackComponent). `tone` :ok | :bad | :warn | :info.
# Los errores quedan más tiempo en pantalla que las confirmaciones.
class Qb::ToastComponent < ViewComponent::Base
  ICONS = { ok: :check, bad: :alert, warn: :alert, info: :bell }.freeze

  def initialize(message:, tone: :ok)
    @message = message
    @tone = ICONS.key?(tone.to_sym) ? tone.to_sym : :info
  end

  attr_reader :message, :tone

  def icon
    ICONS[tone]
  end

  def role
    tone == :bad ? "alert" : "status"
  end

  def duration_ms
    tone == :bad ? 8000 : 5000
  end
end
