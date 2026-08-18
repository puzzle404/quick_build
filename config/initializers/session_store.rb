Rails.application.config.session_store :cookie_store,
  key: "_quick_build_session",
  secure: Rails.env.production?,
  same_site: :lax
