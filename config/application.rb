require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module QuickBuild
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    config.active_job.queue_adapter = :solid_queue

    # Spanish-Argentina locale + timezone — used by qb_fmt_date_short,
    # number formatters, and ActionView helpers like time_ago_in_words.
    config.i18n.default_locale = :"es-AR"
    config.i18n.available_locales = [:"es-AR", :en]
    config.i18n.fallbacks = [:en]
    config.time_zone = "Buenos Aires"
  end
end
