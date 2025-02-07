# frozen_string_literal: true

module Dashboard
  class MessagesController < DashboardController
    def create
      @response = params[:message][:response]
      @conversation = Conversation.find(params[:message][:conversation_id])

      if @response.present?
        @message = @conversation.messages.create!(content: @response, inbox: @conversation.inbox,
account: @conversation.account, sender: current_user)

        Channels::ServicePicker.call(conversation: @conversation, message: @message)
      end

      respond_to do |format|
        format.js { render(js: "document.querySelector('.response-area').value = '';") }
        format.html { redirect_to(request.referer) }
      end
    end

    def append_message
      @message = Message.find(params[:id])
      render(turbo_stream: turbo_stream.append("message-frame", partial: "dashboard/messages/message",
locals: { message: @message }))
    end
  end
end
