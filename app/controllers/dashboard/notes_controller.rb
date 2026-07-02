# frozen_string_literal: true

module Dashboard
  class NotesController < DashboardController
    def edit
      @note = current_account.notes.find(params[:id])
    end
    def create
      @note = Note.new(content: params[:note][:content], account: current_account, user: current_user,
resource: current_user)

      if @note.save
        render(json: { success: true })
      else
        render(json: { success: false })
      end
    end


    def update
      @note = current_account.notes.find(params[:id])
      if @note.update(content: params[:note][:content])
        respond_to do |format|
          format.html { redirect_to(notes_path, notice: "Note updated successfully.") }
          format.turbo_stream do
 render(turbo_stream: turbo_stream.replace("note_#{@note.id}", partial: "dashboard/notes/note",
locals: { note: @note })) end
        end
      else
        render(:edit)
      end
    end

    def destroy
      @note = current_account.notes.find(params[:id])
      @note.destroy

      respond_to do |format|
        format.html { redirect_to(notes_path, notice: "Note deleted successfully.") }
        format.turbo_stream { render(turbo_stream: turbo_stream.remove("note_#{@note.id}")) }
      end
    end
  end
end
