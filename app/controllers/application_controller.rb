class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  include Authenticable
  include Pagy::Backend
  include Pundit::Authorization
  include RolesHelper
  include Cart

  helper QuickbuildHelper
  helper Pagy::Frontend

  before_action :set_mobile_variant
  layout :pick_default_layout

  private

  # Picks the `:mobile` variant whenever the request looks like it came from a
  # phone-sized client — the iOS shell, the installed PWA, a mobile browser,
  # or an explicit dev override. Each source is independent and additive.
  def set_mobile_variant
    apply_dev_variant_override
    return unless mobile_client?
    request.variant = :mobile
  end

  # Dev/test only: `?_variant=mobile` flips the variant for the rest of the
  # session (sticky cookie); `?_variant=desktop` clears it. Lets DevTools
  # responsive mode preview mobile views without spoofing the UA. Production
  # ignores this — only the real signals (UA, PWA cookie, header) count.
  def apply_dev_variant_override
    return unless Rails.env.development? || Rails.env.test?

    case params[:_variant].to_s
    when "mobile"  then cookies[:qb_force_mobile_variant] = { value: "1", path: "/" }
    when "desktop" then cookies.delete(:qb_force_mobile_variant, path: "/")
    end
  end

  # Sources of "this is a phone-shaped client" — any one is enough:
  # 1. Hotwire Native iOS shell sets `Hotwire Native` in the UA.
  # 2. Same shell also sends `Hotwire-Native-Visit` header for redundancy.
  # 3. `qb_mobile_client` cookie is set by the Stimulus mobile-detect
  #    controller (`app/javascript/controllers/qb/mobile_detect_controller.js`)
  #    when the page is opened in standalone PWA mode OR the viewport is
  #    narrower than 768px. The cookie wins over the UA so DevTools
  #    responsive mode is reliable once JS runs.
  # 4. User-Agent regex catches the very first request before any JS runs —
  #    matches iPhones, iPads in mobile mode, and Android phones (not Android
  #    tablets, which set "Android" without "Mobile").
  # 5. Dev override flag (env-gated).
  def mobile_client?
    hotwire_native_app? ||
      request.headers["Hotwire-Native-Visit"].present? ||
      cookies[:qb_mobile_client] == "1" ||
      mobile_user_agent? ||
      dev_variant_forced?
  end
  helper_method :mobile_client?

  MOBILE_UA_REGEX = /\b(iPhone|iPod|Android.*Mobile|Windows Phone)\b/i
  private_constant :MOBILE_UA_REGEX

  def mobile_user_agent?
    return false if cookies[:qb_mobile_client] == "0" # client explicitly opted out
    MOBILE_UA_REGEX.match?(request.user_agent.to_s)
  end

  def dev_variant_forced?
    (Rails.env.development? || Rails.env.test?) && cookies[:qb_force_mobile_variant] == "1"
  end

  # Default layout policy: mobile clients get the slim `mobile` layout for any
  # controller that hasn't picked one explicitly. Subclasses (constructor base,
  # marketing controllers) override with their own `layout :method` and can
  # still call `mobile_layout_or(default)` to keep the policy consistent.
  def pick_default_layout
    mobile_client? ? "mobile" : "application"
  end

  # Helper subclasses use in their own `layout :proc_name` methods so the
  # mobile layout still wins over their normal default.
  def mobile_layout_or(default)
    mobile_client? ? "mobile" : default
  end
end
