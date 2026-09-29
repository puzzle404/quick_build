# frozen_string_literal: true

# PATCH /preferences  — bumps the current user's UI preferences (theme,
# accent, density). Same endpoint covers the desktop tweaks panel and the
# mobile Perfil tab so both clients stay in sync. Anonymous users 401.
class PreferencesController < ApplicationController
  def update
    current = Current.session&.user
    return head :unauthorized unless current

    current.update_preferences!(preference_params)

    respond_to do |format|
      format.json { render json: { theme: current.theme, accent: current.accent, density: current.density } }
      format.turbo_stream { head :no_content }
      format.html { redirect_back fallback_location: root_path, notice: "Preferencias guardadas." }
    end
  end

  private

  def preference_params
    params.fetch(:preferences, {}).permit(:theme, :accent, :density)
  end
end
