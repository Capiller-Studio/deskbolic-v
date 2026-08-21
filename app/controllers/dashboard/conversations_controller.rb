# frozen_string_literal: true

module Dashboard
  class ConversationsController < DashboardController
    def index
      load_navigation

      @conversations = find_conversations(params[:resource_id])
      @conversations = visible_conversations(@conversations)
      apply_sidebar_scope
      @list_counts = conversation_counts(@conversations)

      @query = params[:q].to_s.strip
      @filter = params[:filter].presence
      @conversations = filter_conversations(@conversations, @filter)
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
      load_navigation

      @conversation = current_account.conversations.find(params[:id])
      @inbox = current_account.inboxes.find_by(id: params[:resource_id]) if params[:resource_id].present?
      conversation_scope = @inbox ? @inbox.conversations.where(account: current_account) : current_account.conversations
      @conversations = visible_conversations(conversation_scope)
      apply_sidebar_scope
      @list_counts = conversation_counts(@conversations)

      @query = params[:q].to_s.strip
      @filter = params[:filter].presence
      @filter ||= @conversation.status if @conversation.snoozed? || @conversation.resolved?
      @conversations = filter_conversations(@conversations, @filter)
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

        @activities = @conversation.activities.where.not(event_key: "conversation.update").where(created_at: start_time..end_time)
        @timeline_items = (@messages.to_a + @activities.to_a).sort_by(&:created_at)
      else
        @activities = @conversation.activities.where.not(event_key: "conversation.update")
        @timeline_items = @activities.to_a.sort_by(&:created_at)
      end
      @notes = current_account.notes.where(user: current_user, resource: @conversation)

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
    def update
      @conversation = current_account.conversations.find(params[:id])

      if @conversation.update(conversation_params)
        @teams = current_account.teams.includes(:team_users).order(:name)
        @notes = current_account.notes.where(user: current_user, resource: @conversation)

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

            render(turbo_stream: streams)
          end
          format.html { redirect_to(request.referer || conversations_path) }
        end
      else
        head(:unprocessable_entity)
      end
    end

    def snooz_conversation
      @conversation = current_account.conversations.find(params[:id])
      @conversation.update(
        status: :snoozed,
        data: { "snoozed_until" => params[:snooze_until] }
      )
      redirect_to(conversations_path(resource_id: @conversation.inbox_id))
    end

    def close_conversation
      @conversation = current_account.conversations.find(params[:id])
      @conversation.update(status: :closed)
      redirect_to(conversations_path(resource_id: @conversation.inbox_id))
    end

    def mark_as_read
      @conversation = current_account.conversations.find(params[:id])
      UnreadCounts::Reset.call(@conversation, current_user)
      head(:ok)
    end

    def assign_member
      @conversation = current_account.conversations.find(params[:id])
      user = params[:user_id].present? ? current_account.users.find(params[:user_id]) : current_user
      @conversation.assign!(user)

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.replace(
            "conversation-agent-#{@conversation.id}",
            partial: "dashboard/conversations/agent_info",
            locals: { conversation: @conversation, assigned_conversation: true }
          ))
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def unassign_member
      @conversation = current_account.conversations.find(params[:id])
      @conversation.unassign!

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.replace(
            "conversation-agent-#{@conversation.id}",
            partial: "dashboard/conversations/agent_info",
            locals: { conversation: @conversation, assigned_conversation: false }
          ))
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
          render(turbo_stream: turbo_stream.replace(
            "conversation-team-#{@conversation.id}",
            partial: "dashboard/conversations/team_info",
            locals: { conversation: @conversation, assigned_team: team }
          ))
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
          render(turbo_stream: turbo_stream.replace(
            "conversation-team-#{@conversation.id}",
            partial: "dashboard/conversations/team_info",
            locals: { conversation: @conversation, assigned_team: nil }
          ))
        end
        format.html { redirect_to(request.referer) }
      end
    end

    def add_label
      @conversation = current_account.conversations.find(params[:id])
      label = current_account.labels.find(params[:label_id])

      if @conversation.labels.exclude?(label)
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
          render(turbo_stream: turbo_stream.replace(
            "conversation-labels-#{@conversation.id}",
            partial: "dashboard/conversations/labels_info",
            locals: { conversation: @conversation }
          ))
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
          render(turbo_stream: turbo_stream.replace(
            "conversation-labels-#{@conversation.id}",
            partial: "dashboard/conversations/labels_info",
            locals: { conversation: @conversation }
          ))
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

    def filter_conversations(conversations, filter)
      case filter
      when "assigned"
        conversations.where(status: :active, assignee: current_user)
      when "unassigned"
        conversations.where(status: :active).not_assigned_to_user
      when "mentions"
        conversations.where(id: mentioned_conversation_ids).where(status: :active)
      when "snoozed"
        conversations.where(status: :snoozed)
      when "resolved"
        conversations.where(status: :resolved)
      else
        conversations.where(status: :active)
      end
    end

    def find_conversations(resource_id)
      @inbox = current_account.inboxes.find_by(id: resource_id) if resource_id.present?
      @inbox ? @inbox.conversations.where(account: current_account) : current_account.conversations
    end

    def search_conversations(conversations, query)
      results = Search::SearchService.new(
        query: query,
        account_id: current_account.id,
        type: nil
      ).call

      matching_ids = (results[:conversations].map(&:id) + results[:messages].map(&:conversation_id)).uniq
      return conversations.none if matching_ids.empty?

      conversations.where(id: matching_ids)
    end

    private

    def load_navigation
      @inboxes = current_account.inboxes.all
      @teams = current_account.teams.includes(:team_users).order(:name)
      @team_users = @teams.flat_map(&:team_users).reject { |team_user| team_user.user_id == current_user.id }.uniq(&:user_id)
      @team_id = params[:team_id].presence
      @assignee_id = params[:assignee_id].presence
      @filter = params[:filter].presence
      @sidebar_counts = conversation_counts(visible_conversations(current_account.conversations))
    end

    def visible_conversations(scope)
      scope.current_conversations(current_user).or(scope.not_assigned_to_user).distinct
    end

    def apply_sidebar_scope
      @conversations = @conversations.where(team_id: @team_id) if @team_id.present?

      return unless @assignee_id.present?

      assignee = current_account.users.find(@assignee_id)
      @conversations = current_account.conversations.where(assignee: assignee)
      @inbox = nil
    end

    def conversation_counts(scope)
      {
        all: scope.where(status: :active).count,
        assigned: scope.where(status: :active, assignee: current_user).count,
        unassigned: scope.where(status: :active, assignee_id: nil).count,
        mentions: scope.where(id: mentioned_conversation_ids, status: :active).count,
        snoozed: scope.where(status: :snoozed).count,
        resolved: scope.where(status: :resolved).count
      }
    end

    def mentioned_conversation_ids
      @mentioned_conversation_ids ||= begin
        message_ids = current_account.mentions.where(
          mentioned: current_user,
          resource_type: "Message"
        ).select(:resource_id)

        current_account.messages.where(id: message_ids).select(:conversation_id)
      end
    end

    def conversation_params
      params.expect(conversation: [ :status, :priority ])
    end
  end
end
