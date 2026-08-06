# frozen_string_literal: true

module Dashboard
  class AiAgentsController < DashboardController
    before_action :set_ai_agent, only: %i[edit update destroy]

    def index
      current_account.with_shard do
        @pagy, @ai_agents = pagy(
          Ai::Agent.where(account: current_account).order(created_at: :desc),
          page_param: :page, limit: 20
        )
      end
    end

    def new
      @ai_agent = Ai::Agent.new(status: :active, agent_type: :help_center_bot, confidence_threshold: 0.7, max_exchanges: 5)
    end

    def create
      current_account.with_shard do
        @ai_agent = Ai::Agent.new(ai_agent_params.merge(account: current_account))
        
        if @ai_agent.save
          redirect_to ai_agents_path, notice: t('dashboard.ai_agents.messages.created', default: 'AI Agent created successfully.')
        else
          render :new, status: :unprocessable_entity
        end
      end
    end

    def edit
    end

    def update
      current_account.with_shard do
        if @ai_agent.update(ai_agent_params)
          redirect_to ai_agents_path, notice: t('dashboard.ai_agents.messages.updated', default: 'AI Agent updated successfully.')
        else
          render :edit, status: :unprocessable_entity
        end
      end
    end

    def destroy
      current_account.with_shard do
        @ai_agent.destroy
        redirect_to ai_agents_path, notice: t('dashboard.ai_agents.messages.deleted', default: 'AI Agent deleted successfully.')
      end
    end

    private

    def set_ai_agent
      current_account.with_shard do
        @ai_agent = Ai::Agent.find_by!(id: params[:id], account: current_account)
      end
    end

    def ai_agent_params
      params.require(:ai_agent).permit(
        :name,
        :status,
        :agent_type,
        :tone,
        :system_prompt,
        :max_exchanges,
        :confidence_threshold,
        :portal_id,
        translations_attributes: [:id, :locale, :greeting_message, :handoff_message, :fallback_message, :_destroy]
      )
    end
  end
end
