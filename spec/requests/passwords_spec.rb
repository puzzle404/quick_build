require 'rails_helper'

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user) }

  # deliver_later needs the :test adapter for have_enqueued_mail (the app
  # default is :solid_queue). Swap it only for these examples.
  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  describe "GET /passwords/new" do
    it "renders the request form without authentication" do
      get new_password_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recuperar contraseña")
    end
  end

  describe "POST /passwords" do
    it "enqueues the reset email for a known user and redirects with a neutral notice" do
      expect {
        post passwords_path, params: { email: user.email }
      }.to have_enqueued_mail(PasswordsMailer, :reset).with(user)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Si tu email está registrado")
    end

    it "responds identically for an unknown email (does not leak existence)" do
      expect {
        post passwords_path, params: { email: "nadie@example.com" }
      }.not_to have_enqueued_mail

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to include("Si tu email está registrado")
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the new-password form with a valid token" do
      get edit_password_path(user.password_reset_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nueva contraseña")
    end

    it "redirects to passwords/new with an invalid token" do
      get edit_password_path("token-invalido")

      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /passwords/:token" do
    it "resets the password with a valid token (happy path)" do
      patch password_path(user.password_reset_token),
            params: { password: "nueva-clave-123", password_confirmation: "nueva-clave-123" }

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("nueva-clave-123")).to be_truthy
    end

    it "re-renders the form when the confirmation does not match" do
      patch password_path(user.password_reset_token),
            params: { password: "nueva-clave-123", password_confirmation: "otra-cosa" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.authenticate("password")).to be_truthy
    end

    it "rejects an invalid token without changing the password" do
      patch password_path("token-invalido"),
            params: { password: "nueva-clave-123", password_confirmation: "nueva-clave-123" }

      expect(response).to redirect_to(new_password_path)
      expect(user.reload.authenticate("password")).to be_truthy
    end
  end
end
