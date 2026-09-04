# frozen_string_literal: true

module Dashboard
  class MessagesController < DashboardController
    def index
      @conversation = current_account.conversations.find(params[:conversation_id])
      @pagy, @messages = pagy(@conversation.messages.includes(:attachments).order(created_at: :desc), items: 20)
      @messages = @messages.reverse

      if @messages.any?
        start_time = @messages.first.created_at
        end_time = @messages.last.created_at

        start_time = 10.years.ago if @pagy.page == @pagy.last
        end_time = 10.years.from_now if @pagy.page == 1

        @activities = @conversation.activities.where.not(event_key: "conversation.update").where(created_at: start_time..end_time)
        @timeline_items = (@messages.to_a + @activities.to_a).sort_by(&:created_at)
      else
        @activities = @conversation.activities.where.not(event_key: "conversation.update")
        @timeline_items = @activities.to_a.sort_by(&:created_at)
      end
      render(layout: false)
    end

    def create
      @response = params[:message][:response]
      @attachments = params[:message][:attachments]&.reject(&:blank?)
      @visibility = params[:message][:visibility] == "personal" ? "personal" : "global"
      @resolve_after_send = params[:message][:resolve_conversation] == "1"
      @conversation = current_account.conversations.find(params[:message][:conversation_id])

      if @response.present? || @attachments.present?
        unless @conversation.assigned?
          @conversation.assign!(current_user)
        end

        @messages = Messages::MessageCreator.call(
          conversation: @conversation,
          content: @response,
          attachments: @attachments,
          sender: current_user,
          visibility: @visibility
        )
        @message = @messages.first

        if @message&.personal? && @message.content.present?
          parse_mentions(@message)
        end

        @conversation.update!(status: :resolved) if @resolve_after_send
      end

      respond_to do |format|
        format.turbo_stream do
          if @resolve_after_send && @message&.persisted?
            redirect_to(request.referer || conversations_path(resource_id: @conversation.inbox_id), status: :see_other)
          else
            render(:create)
          end
        end
        format.js do
          script = "document.querySelector('.response-area').value = ''; document.dispatchEvent(new CustomEvent('deskbolic:message-sent'));"
          script += " window.location.reload();" if @resolve_after_send && @message&.persisted?
          render(js: script)
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def append_message
      @message = current_account.messages.find(params[:id])
      streams = []

      if params[:active_conversation_id] == @message.conversation_id
        streams << turbo_stream.append("message-frame", partial: "dashboard/messages/message", locals: { message: @message, show_divider: true })
      end

      streams << turbo_stream.update("conversation-#{@message.conversation_id}-preview", ActionController::Base.helpers.strip_tags(@message.content.to_s)&.truncate(100))
      streams << turbo_stream.update("conversation-#{@message.conversation_id}-date", helpers.conversation_list_time(@message.created_at))

      render(turbo_stream: streams)
    end

    def update_message
      @message = current_account.messages.find(params[:id])
      render(turbo_stream: turbo_stream.replace(ActionView::RecordIdentifier.dom_id(@message), partial: "dashboard/messages/message", locals: { message: @message, show_divider: false }))
    end

    def translate
      @message = current_account.messages.find(params[:id])
      target_locale = I18n.locale.to_s

      translated_text = Integrations::Translators::Engine.new(message: @message, target_locale: target_locale).call

      if translated_text.present?
        render(json: { success: true, text: translated_text })
      else
        render(json: { success: false, error: I18n.t("dashboard.messages.translation_failed", default: "Translation failed.") }, status: :unprocessable_entity)
      end
    end

    private

    def parse_mentions(message)
      mentions = message.content.scan(/@(\w+)/).flatten.uniq
      return if mentions.empty?

      users = current_account.users.where("LOWER(first_name) IN (?) OR LOWER(last_name) IN (?)", mentions.map(&:downcase), mentions.map(&:downcase))

      users.each do |user|
        Mention.create!(
          account: current_account,
          resource: message,
          mentioned: user
        )
      end
    end
  end
end
