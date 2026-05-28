# frozen_string_literal: true

# JSON endpoint backing the QB OS command palette. Returns grouped results
# scoped to the constructor's owned data.
class Constructors::SearchController < Constructors::BaseController
  def index
    @current_qb_section = :search
    @query = params[:q].to_s
    @scope = params[:scope].to_s.presence_in(%w[projects stages materials documents people]) || 'all'
    @results = Constructors::SearchService.new(user: current_user, query: @query).call

    respond_to do |format|
      format.json { render json: @results }
      format.html # JSON-only on desktop has been the contract; mobile variant renders the full UI.
    end
  end
end
