# frozen_string_literal: true

# JSON endpoint backing the QB OS command palette. Returns grouped results
# scoped to the constructor's owned data.
class Constructors::SearchController < Constructors::BaseController
  def index
    @results = Constructors::SearchService.new(user: current_user, query: params[:q]).call

    respond_to do |format|
      format.json { render json: @results }
    end
  end
end
