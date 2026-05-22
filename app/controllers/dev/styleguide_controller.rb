# frozen_string_literal: true

# Dev-only catalog of the Quick Build OS primitive components. Lives at
# /dev/styleguide in development; the route isn't wired in production.
class Dev::StyleguideController < ApplicationController
  allow_unauthenticated_access
  layout 'application'

  def show; end
end
