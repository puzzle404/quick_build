# frozen_string_literal: true

class PasswordsMailer < ApplicationMailer
  default from: ENV.fetch("CONTACT_FORM_SENDER", "no-reply@quickbuild.com")

  def reset(user)
    @user = user
    mail(subject: "Restablecé tu contraseña · Quick Build", to: user.email)
  end
end
