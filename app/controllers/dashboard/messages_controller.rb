# frozen_string_literal: true

module Dashboard
  class MessagesController < DashboardController
    def index
      @conversation = Conversation.find(params[:conversation_id])
      @pagy, @messages = pagy(@conversation.messages.includes(:attachments).order(created_at: :desc), items: 20)
      @messages = @messages.reverse
      render layout: false
    end

    def create
      @response = params[:message][:response]
      @attachments = params[:message][:attachments].reject(&:blank?)
      @conversation = Conversation.find(params[:message][:conversation_id])

      if @response.present? || @attachments.present?
        unless @conversation.assigned?
          @conversation.assign!(current_user)
        end
        
        @message = @conversation.messages.create!(content: @response,inbox: @conversation.inbox,
        account: @conversation.account,sender: current_user,source: @conversation.source)

        create_attachments(@attachments) if @attachments.present?
        Messages::DeliveryWorker.perform_async(@message.account_id, @message.id)
      end

      respond_to do |format|
        format.turbo_stream
        format.js { render(js: "document.querySelector('.response-area').value = ''; document.dispatchEvent(new CustomEvent('deskbolic:message-sent'));") }
        format.html { redirect_to(request.referer) }
      end
    end

    def append_message
      @message = Message.find(params[:id])
      streams = []
      
      if params[:active_conversation_id] == @message.conversation_id
        streams << turbo_stream.append("message-frame", partial: "dashboard/messages/message", locals: { message: @message, show_divider: true })
      end
      
      streams << turbo_stream.update("conversation-#{@message.conversation_id}-preview", @message.content.to_s)
      streams << turbo_stream.update("conversation-#{@message.conversation_id}-date", @message.created_at.strftime("%d %b"))
      
      render(turbo_stream: streams)
    end

    def update_message
      @message = Message.find(params[:id])
      render(turbo_stream: turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@message), partial: "dashboard/messages/message", locals: { message: @message, show_divider: false }))
    end

    private

    def create_attachments(attachments)
      attachments.each do |file|
        @message.attachments.create!(
          account: @conversation.account,
          file: file,
          attachment_type: detect_attachment_type(file)
        )
      end
    end

    def detect_attachment_type(file)
      case file.content_type
      when %r{\Aimage/} then :image
      when %r{\Avideo/} then :video
      when %r{\Aaudio/} then :audio
      else :file
      end
    end
  end
end
