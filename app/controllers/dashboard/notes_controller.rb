# frozen_string_literal: true

module Dashboard
  class NotesController < DashboardController
    def create
      @note = Note.new(content: params[:note][:content], account: current_account, user: current_user, resource: current_user)

      if @note.save
        render json: { success: true }
      else
        render json: { success: false }
      end
    end
  end
end