# frozen_string_literal: true

module RequestAuthHelpers
  def sign_in(user, password: "password")
    post session_path, params: { session: { email: user.email, password: password } }
  end
end
