# frozen_string_literal: true

module Dashboard
  class ConversationsController < DashboardController
    def index
      @inboxes = current_account.inboxes.all
      @teams = current_account.teams.includes(:team_users).order(:name)
      @team_users = @teams.flat_map(&:team_users).reject { |tu| tu.user_id == current_user.id }.uniq(&:user_id)

      @conversations = find_conversations(params[:resource_id])
      @conversations = @conversations.current_conversations(current_user).or(@conversations.not_assigned_to_user)

      @query = params[:q].to_s.strip
      @filter = params[:filter].presence
      @conversations = filter_conversations(@filter) if @filter.present?
      @conversations = search_conversations(@conversations, @query) if @query.present?
      @conversations = @conversations.includes(:customers, :last_message).order(last_activity_at: :desc)
      @pagy_conversations, @conversations = pagy(@conversations, items: 20)
      
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
      @inboxes = current_account.inboxes.all
      @teams = current_account.teams.includes(:team_users).order(:name)
      @team_users = @teams.flat_map(&:team_users).reject { |tu| tu.user_id == current_user.id }.uniq(&:user_id)

      @conversation = current_account.conversations.find(params[:id])
      @inbox = @conversation.inbox
      @conversations = @inbox.conversations.where(account: current_account).where(status: @conversation.status)
      @conversations = @conversations.current_conversations(current_user).or(@conversations.not_assigned_to_user)

      @query = params[:q].to_s.strip
      @filter = params[:filter].presence
      @conversations = filter_conversations(@filter) if @filter.present?
      @conversations = search_conversations(@conversations, @query) if @query.present?
      @conversations = @conversations.includes(:customers, :last_message).order(last_activity_at: :desc)
      @pagy_conversations, @conversations = pagy(@conversations, items: 20, page_param: :conversations_page)

      @pagy, @messages = pagy(@conversation.messages.includes(:attachments).order(created_at: :desc), items: 20)
      @messages = @messages.reverse
      
      if @messages.any?
        start_time = @messages.first.created_at
        end_time = @messages.last.created_at
        
        start_time = 10.years.ago if @pagy.page == @pagy.last
        end_time = 10.years.from_now if @pagy.page == 1
        
        @activities = @conversation.activities.where.not(event_key: 'conversation.update').where(created_at: start_time..end_time)
        @timeline_items = (@messages.to_a + @activities.to_a).sort_by(&:created_at)
      else
        @activities = @conversation.activities.where.not(event_key: 'conversation.update')
        @timeline_items = @activities.to_a.sort_by(&:created_at)
      end
      @canned_responses = CannedResponse.where(account: current_account).all
      @notes = Note.where(account: current_account, user: current_user).all

      # Fetch unread count before resetting
      key = RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: current_account.id, member_id: current_user.id }
      @unread_count = RedisUtilities::Helpers.hash_get(key, @conversation.id).to_i
      
      if @unread_count > 0 && @messages.size >= @unread_count
        @unread_start_message_id = @messages[@messages.size - @unread_count].id
      end

      # Reset unread counts
      UnreadCounts::Reset.call(@conversation, current_user)

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.update(
            "messages-frame",
            partial: "dashboard/messages/messages",
            locals: { timeline_items: @timeline_items }
          ))
        end
        format.html
      end
    end

    def update
      @conversation = current_account.conversations.find(params[:id])
      
      if @conversation.update(conversation_params)
        @teams = current_account.teams.includes(:team_users).order(:name)
        @notes = Note.where(account: current_account, user: current_user).all

        respond_to do |format|
          format.turbo_stream do
            streams = []
            
            # Re-render the conversation in the left sidebar list
            streams << turbo_stream.replace(
              ActionView::RecordIdentifier.dom_id(@conversation),
              partial: "dashboard/conversations/conversation",
              locals: { conversation: @conversation }
            )

            # Re-render the details panel
            streams << turbo_stream.replace(
              "conversation-details-#{@conversation.id}",
              partial: "dashboard/conversations/conversation_details",
              locals: { conversation: @conversation, assigned_team: @conversation.team }
            )
            
            render turbo_stream: streams
          end
          format.html { redirect_to request.referer || conversations_path }
        end
      else
        head :unprocessable_entity
      end
    end
    def create
      channel   = current_account.facebook_pages.find(params[:channel_id])
      customer  = current_account.customers.find(params[:customer_id])
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

    def snooz_conversation
      @conversation = current_account.conversations.find(params[:id])
      @conversation.update(
        status: :snoozed,
        data: { "snoozed_until" => params[:snooze_until] }
      )
      redirect_to conversations_path(resource_id: @conversation.inbox_id)
    end
    
    def close_conversation
      @conversation = current_account.conversations.find(params[:id])
      @conversation.update(status: :closed)
      redirect_to conversations_path(resource_id: @conversation.inbox_id)
    end
    
    def mark_as_read
      @conversation = current_account.conversations.find(params[:id])
      UnreadCounts::Reset.call(@conversation, current_user)
      head :ok
    end
    
    def assign_member
      @conversation = current_account.conversations.find(params[:id])
      user = params[:user_id].present? ? current_account.users.find(params[:user_id]) : current_user
      @conversation.assign!(user)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conversation-agent-#{@conversation.id}", 
            partial: "dashboard/conversations/agent_info", 
            locals: { conversation: @conversation, assigned_conversation: true }
          )
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def unassign_member
      @conversation = current_account.conversations.find(params[:id])
      @conversation.unassign!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conversation-agent-#{@conversation.id}", 
            partial: "dashboard/conversations/agent_info", 
            locals: { conversation: @conversation, assigned_conversation: false }
          )
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def assign_team
      @conversation = current_account.conversations.find(params[:id])
      team = current_account.teams.find(params[:team_id])
      @conversation.assign_team!(team)

      @teams = current_account.teams
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conversation-team-#{@conversation.id}", 
            partial: "dashboard/conversations/team_info", 
            locals: { conversation: @conversation, assigned_team: team }
          )
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def unassign_team
      @conversation = current_account.conversations.find(params[:id])
      @conversation.unassign_team!
      
      @teams = current_account.teams
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conversation-team-#{@conversation.id}", 
            partial: "dashboard/conversations/team_info", 
            locals: { conversation: @conversation, assigned_team: nil }
          )
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def add_label
      @conversation = current_account.conversations.find(params[:id])
      label = current_account.labels.find(params[:label_id])
      
      if !@conversation.labels.include?(label)
        @conversation.labels << label
        Activities::Recorder.call(
          trackable: @conversation,
          event_type: "label_added",
          changes: { label: label.title },
          actor: Current.user
        )
      end
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conversation-labels-#{@conversation.id}",
            partial: "dashboard/conversations/labels_info",
            locals: { conversation: @conversation }
          )
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def remove_label
      @conversation = current_account.conversations.find(params[:id])
      label = current_account.labels.find(params[:label_id])
      
      if @conversation.labels.include?(label)
        @conversation.labels.delete(label)
        Activities::Recorder.call(
          trackable: @conversation,
          event_type: "label_removed",
          changes: { label: label.title },
          actor: Current.user
        )
      end
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conversation-labels-#{@conversation.id}",
            partial: "dashboard/conversations/labels_info",
            locals: { conversation: @conversation }
          )
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def append_conversation
      @conversation = current_account.conversations.find(params[:id])
      @active_conversation_id = params[:active_conversation_id]
      render(turbo_stream: turbo_stream.prepend(
        "conversations-list",
        partial: "dashboard/conversations/conversation",
        locals: { conversation: @conversation }
      ))
    end

    def reorder_conversation
      @conversation = current_account.conversations.find(params[:id])
      @active_conversation_id = params[:active_conversation_id]
      streams = []
      streams << turbo_stream.remove(ActionView::RecordIdentifier.dom_id(@conversation))
      streams << turbo_stream.prepend(
        "conversations-list",
        partial: "dashboard/conversations/conversation",
        locals: { conversation: @conversation }
      )
      # Also update the preview text and date in case content changed
      streams << turbo_stream.update("conversation-#{@conversation.id}-preview", @conversation.last_message_preview)
      streams << turbo_stream.update("conversation-#{@conversation.id}-date", @conversation.last_message_date)
      render(turbo_stream: streams)
    end

    def filter_conversations(filter)
      case filter
        when "assigned" 
          @conversations.where(assignee: current_user)
        when "unassigned"
          @conversations.not_assigned_to_user
        else
          @conversations.current_conversations(current_user).or(@conversations.not_assigned_to_user)
        end
    end

    def find_conversations(resource_id)
      @inbox = current_account.inboxes.find_by(id: resource_id) if resource_id.present?
      @inbox ? @inbox.conversations.where(account: current_account) : current_account.conversations
    end

    def search_conversations(conversations, query)
      conversations
        .left_joins(:customers, :messages)
        .where(
          <<~SQL.squish,
            conversations.title ILIKE :query
            OR conversations.identifier ILIKE :query
            OR customers.name ILIKE :query
            OR customers.display_name ILIKE :query
            OR customers.first_name ILIKE :query
            OR customers.middle_name ILIKE :query
            OR customers.last_name ILIKE :query
            OR customers.email ILIKE :query
          SQL
          query: "%#{query}%"
        )
        .distinct
    end

    private

    def conversation_params
      params.require(:conversation).permit(:status, :priority)
    end
  end
end