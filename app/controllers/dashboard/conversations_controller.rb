# frozen_string_literal: true

module Dashboard
  class ConversationsController < DashboardController
    def index
      @em_channels = Channel::Email.where(account: current_account).all
      @fb_channels = Channel::FacebookPage.where(account: current_account).all
      @wa_channels = Channel::Whatsapp.where(account: current_account).all

      @inbox = Inbox.find(params[:resource_id])
      @conversations = @inbox.conversations.where(account: current_account)
      @conversations = @conversations.current_conversations(current_user)

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.update(
            "conversations-frame",
            partial: "dashboard/conversations/conversations",
            locals: { conversations: @conversations }
          ))
        end
        format.html
      end
    end

    def show
      @em_channels = Channel::Email.where(account: current_account).all
      @fb_channels = Channel::FacebookPage.where(account: current_account).all
      @wa_channels = Channel::Whatsapp.where(account: current_account).all

      @conversation = Conversation.find(params[:resource_id])
      @conversations = @conversation.inbox.conversations.where(account: current_account)
      @conversations = @conversations.current_conversations(current_user)

      @messages = @conversation.messages
      @canned_responses = CannedResponse.where(account: current_account).all
      @notes = Note.where(account: current_account, user: current_user).all

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.update(
            "messages-frame",
            partial: "dashboard/messages/messages",
            locals: { messages: @messages }
          ))
        end
        format.html
      end
    end
    def create
      channel   = Channel::FacebookPage.find(params[:channel_id])
      customer  = Customer.find(params[:customer_id])
      message   = params[:response]

      conversation_source = params[:conversation_source]

      Conversations::ConversationCreator.call(
        channel: channel,
        message: message,
        sender: current_user,
        customer: customer,
        conversation_source: conversation_source
      )
    end


    def append_conversation
      @conversation = Conversation.find(params[:id])
      render(turbo_stream: turbo_stream.append(
        "conversation-frame",
        partial: "dashboard/conversations/conversation",
        locals: { conversation: @conversation }
      ))
    end
  end
end
