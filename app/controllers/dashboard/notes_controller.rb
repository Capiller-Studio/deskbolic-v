# frozen_string_literal: true

module Dashboard
  class NotesController < DashboardController
    def edit
      @note = current_account.notes.find(params[:id])
    end
    def create
      resource_type = params[:note][:resource_type] || "User"
      resource_id = params[:note][:resource_id] || current_user.id

      resource = if resource_type == "Conversation"
                   current_account.conversations.find(resource_id)
      else
                   current_user
      end

      @note = Note.new(
        content: params[:note][:content],
        account: current_account,
        user: current_user,
        resource: resource
      )

      if @note.save
        respond_to do |format|
          format.turbo_stream do
            render(turbo_stream: turbo_stream.append("conversation-notes", partial: "dashboard/notes/note", locals: { note: @note }))
          end
          format.json { render(json: { success: true }) }
        end
      else
        respond_to do |format|
          format.turbo_stream { head(:unprocessable_entity) }
          format.json { render(json: { success: false }) }
        end
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
