# frozen_string_literal: true

module Dashboard
  class AiAgentsController < DashboardController
    before_action :set_ai_agent, only: %i[edit update destroy]

    def index
      current_account.with_shard do
        agents = Ai::Agent.where(account: current_account)
        status_counts = agents.group(:status).count
        @ai_agent_counts = {
          all: agents.count,
          active: status_counts.fetch("active", 0),
          inactive: status_counts.fetch("inactive", 0)
        }
        @pagy, @ai_agents = pagy(
          agents.includes(:portal).order(created_at: :desc),
          page_param: :page, limit: 20
        )
      end
    end

    def new
      @ai_agent = Ai::Agent.new(name: nil, status: :active, agent_type: nil, tone: nil, confidence_threshold: 0.7, max_exchanges: 5)
    end

    def edit
    end
    def create
      current_account.with_shard do
        @ai_agent = Ai::Agent.new(ai_agent_params.merge(account: current_account))

        if @ai_agent.save
          redirect_to(ai_agents_path, notice: t("dashboard.ai_agents.messages.created", default: "AI Agent created successfully."))
        else
          render(:new, status: :unprocessable_entity)
        end
      end
    end


    def update
      current_account.with_shard do
        if @ai_agent.update(ai_agent_params)
          redirect_to(ai_agents_path, notice: t("dashboard.ai_agents.messages.updated", default: "AI Agent updated successfully."))
        else
          render(:edit, status: :unprocessable_entity)
        end
      end
    end

    def destroy
      current_account.with_shard do
        @ai_agent.destroy
        redirect_to(ai_agents_path, notice: t("dashboard.ai_agents.messages.deleted", default: "AI Agent deleted successfully."))
      end
    end

    private

    def set_ai_agent
      current_account.with_shard do
        @ai_agent = Ai::Agent.find_by!(id: params[:id], account: current_account)
      end
    end

    def ai_agent_params
      params.expect(
        ai_agent: [ :name,
        :status,
        :agent_type,
        :tone,
        :system_prompt,
        :max_exchanges,
        :confidence_threshold,
        :portal_id,
        translations_attributes: [ :id, :locale, :greeting_message, :handoff_message, :fallback_message, :_destroy ] ]
      )
    end
  end
end
