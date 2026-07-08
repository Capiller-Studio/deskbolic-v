module Dashboard
  class ReportsController < DashboardController
    def index
      # Define the time range (last 30 days)
      @start_date = 30.days.ago.beginning_of_day
      @end_date = Time.current.end_of_day

      # Fetch Conversations created in the last 30 days
      @recent_conversations = current_account.conversations.where(created_at: @start_date..@end_date)
      
      # KPIs
      @total_conversations_count = @recent_conversations.count
      
      # Grouped data for Charts
      @conversations_by_day = @recent_conversations.group_by_day(:created_at).count

      # SLA Breaches
      @sla_breaches_count = @recent_conversations
        .joins(:conversation_slas)
        .where(conversation_slas: { status: :breached })
        .count

      # CSAT Average (1-5 scale)
      @csat_avg = Csat::SurveyResponse.where(account_id: current_account.id).average(:rating).to_f.round(1) rescue 0.0

      # Agent Workload
      @agent_workload = @recent_conversations.where.not(assignee_id: nil).group(:assignee_id).count
      @agents = current_account.users.where(id: @agent_workload.keys).index_by(&:id)
    end
  end
end
