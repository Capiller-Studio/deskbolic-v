# frozen_string_literal: true

module Dashboard
  class MessagesController < DashboardController
    def create
      @response = params[:message][:response]
      @conversation = Conversation.find(params[:message][:conversation_id])

      if @response.present?
        unless @conversation.conversation_members.assignees.exists?
          @conversation.conversation_members.find_or_create_by(member: current_user, member_type: "User") do |conversation_member|
            conversation_member.account = current_account
            conversation_member.role = :assignee
          end
        end
        
        @message = @conversation.messages.create!(content: @response, inbox: @conversation.inbox,
account: @conversation.account, sender: current_user)

        Messages::DeliveryWorker.perform_async(@message.account_id, @message.id)
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
