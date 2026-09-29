# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara/cuprite'

Capybara.register_driver(:cuprite) do |app|
  headful = ENV['HEADFUL'].to_s.strip != '' || ENV['SHOW_BROWSER'].to_s.strip != ''
  Capybara::Cuprite::Driver.new(
    app,
    headless: !headful,
    window_size: [1400, 1400],
    js_errors: false,
    process_timeout: 20
  )
end

Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = 5

