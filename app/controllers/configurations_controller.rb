class ConfigurationsController < ApplicationController
  allow_unauthenticated_access

  def ios_v1
    render json: {
      settings: {
        enable_feature_x: true
      },
      rules: [
        {
          patterns: [
            "/new$",
            "/edit$",
            "/modal",
            "/session/new$"
          ],
          properties: {
            context: "modal",
            pull_to_refresh_enabled: false
          },
          comment: "Present forms and custom modal path as modals."
        },
        {
          patterns: [
            "/session/new$"
          ],
          properties: {
            context: "default",
            pull_to_refresh_enabled: false
          },
          comment: "Present session and custom path as default."
        },
        {
          patterns: [
            "/numbers$"
          ],
          properties: {
            view_controller: "numbers"
          },
          comment: "Intercept with a native view."
        },
        {
          patterns: [
            "^/$"
          ],
          properties: {
            presentation: "clear_all"
          },
          comment: "Reset navigation stacks when visiting root page."
        },
        {
          patterns: [ refresh_app_path ],
          properties: {presentation: "refresh", view_controller: "refresh_app"}
        }
      ]
    }
  end

  def android_v1
    render json: {
      settings: {},
      rules: [
        {
          patterns: [
            ".*"
          ],
          properties: {
            context: "default",
            uri: "hotwire://fragment/web",
            fallback_uri: "hotwire://fragment/web",
            pull_to_refresh_enabled: true
          }
        },
        {
          patterns: [
            "^$",
            "^/$"
          ],
          properties: {
            presentation: "clear_all",
            comment: "Clear navigation stack when visiting root page."
          }
        },
        {
          patterns: [
            "/new$",
            "/edit$",
            "/modal"
          ],
          properties: {
            context: "modal",
            pull_to_refresh_enabled: false
          }
        },
        {
          patterns: [
            "/numbers$"
          ],
          properties: {
            uri: "hotwire://fragment/numbers",
            title: "Numbers",
            comment: "Intercept with a native view."
          }
        },
        {
          patterns: [
            "/numbers/[0-9]+$"
          ],
          properties: {
            context: "modal",
            uri: "hotwire://fragment/web/modal/sheet",
            pull_to_refresh_enabled: false
          }
        },
        {
          patterns: [
            ".+\\.(?:bmp|gif|heic|jpg|jpeg|png|svg|webp)"
          ],
          properties: {
            context: "modal",
            uri: "hotwire://fragment/image_viewer"
          }
        }
      ]
    }
  end
end
