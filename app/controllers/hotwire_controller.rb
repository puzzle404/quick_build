class HotwireController < ApplicationController
  allow_unauthenticated_access only: %i[refresh]

  def refresh
    
  end
end
