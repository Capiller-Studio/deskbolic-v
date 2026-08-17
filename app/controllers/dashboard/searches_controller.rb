# frozen_string_literal: true

module Dashboard
  class SearchesController < DashboardController
    def index
      @query = params[:q].to_s.strip
      @type = params[:type].presence # "conversations", "messages", or nil for all
      @page = [ params[:page].to_i, 1 ].max

      filters = {
        inbox_id: params[:inbox_id].presence,
        status: params[:status].presence,
        priority: params[:priority].presence,
        assignee_id: params[:assignee_id].presence,
        team_id: params[:team_id].presence,
        date_from: params[:date_from].presence,
        date_to: params[:date_to].presence
      }.compact

      service = Search::SearchService.new(
        query: @query,
        account_id: current_account.id,
        filters: filters,
        page: @page,
        per_page: 20,
        type: @type
      )

      results = service.call
      @conversations = results[:conversations]
      @messages = results[:messages]

      @inboxes = current_account.inboxes.all
      @teams = current_account.teams.order(:name)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def suggestions
      query = params[:q].to_s.strip

      service = Search::SearchService.new(
        query: query,
        account_id: current_account.id
      )

      results = service.suggestions

      conversations = results[:conversations].map do |conv|
        customer = conv.customers.first
        {
          id: conv.id,
          identifier: conv.identifier,
          title: conv.title,
          status: conv.status,
          priority: conv.priority,
          customer_name: customer&.name || customer&.display_name,
          customer_email: customer&.email,
          inbox_name: conv.inbox&.name,
          last_activity_at: conv.last_activity_at&.strftime("%d %b %Y"),
          url: conversation_path(conv)
        }
      end

      messages = results[:messages].map do |msg|
        highlighted = msg.search_highlights.dig(:content) || ActionController::Base.helpers.strip_tags(msg.content.to_s).truncate(150)
        {
          id: msg.id,
          content: highlighted,
          sender_name: msg.sender.try(:name) || msg.sender.try(:display_name),
          sender_type: msg.sender_type,
          conversation_id: msg.conversation_id,
          conversation_identifier: msg.conversation&.identifier,
          created_at: msg.created_at&.strftime("%d %b %Y, %H:%M"),
          url: conversation_path(msg.conversation_id, anchor: "message_#{msg.id}")
        }
      end

      render(json: { conversations: conversations, messages: messages })
    end
  end
end
