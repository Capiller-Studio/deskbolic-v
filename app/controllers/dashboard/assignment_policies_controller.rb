# frozen_string_literal: true

module Dashboard
  class AssignmentPoliciesController < DashboardController
    before_action :set_policy, only: [:show, :edit, :update, :destroy, :toggle]

    def index
      authorize(AssignmentPolicy)

      @policies = current_account.assignment_policies.includes(:inboxes).order(:position)
      @policies = @policies.where(strategy: params[:strategy]) if params[:strategy].present?
    end

    def show
      authorize(@policy)
    end

    def new
      @policy = current_account.assignment_policies.new(strategy: params[:strategy] || :round_robin)
      authorize(@policy)
      load_form_data
    end

    def create
      @policy = current_account.assignment_policies.new(policy_params)
      authorize(@policy)

      if @policy.save
        sync_inboxes
        redirect_to(assignment_policies_path, notice: t(".created"))
      else
        load_form_data
        render(:new, status: :unprocessable_entity)
      end
    end

    def edit
      authorize(@policy)
      load_form_data
    end

    def update
      authorize(@policy)

      if @policy.update(policy_params)
        sync_inboxes
        redirect_to(assignment_policies_path, notice: t(".updated"))
      else
        load_form_data
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      authorize(@policy)
      @policy.destroy!

      respond_to do |format|
        format.turbo_stream { render(turbo_stream: turbo_stream.remove("policy_#{@policy.id}")) }
        format.html { redirect_to(assignment_policies_path, notice: t(".destroyed")) }
      end
    end

    def toggle
      authorize(@policy)
      @policy.toggle!

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.replace(
            "policy_#{@policy.id}",
            partial: "dashboard/assignment_policies/policy_card",
            locals: { policy: @policy }
          ))
        end
        format.html { redirect_to(assignment_policies_path) }
      end
    end

    def reorder
      authorize(AssignmentPolicy)
      ordered_ids = params[:ordered_ids]
      return head(:bad_request) if ordered_ids.blank?

      ActiveRecord::Base.transaction do
        ordered_ids.each_with_index do |id, index|
          current_account.assignment_policies.where(id: id).update_all(position: index + 1) # rubocop:disable Rails/SkipsModelValidations
        end
      end

      head(:ok)
    end

    private

    def set_policy
      @policy = current_account.assignment_policies.find(params[:id])
    end

    def load_form_data
      @inboxes = current_account.inboxes.order(:name)
      @business_hour_groups = current_account.business_hour_groups.order(:name)
      @skills = current_account.skills.active.ordered
    end

    def sync_inboxes
      inbox_ids = params.dig(:assignment_policy, :inbox_ids)&.reject(&:blank?) || []
      @policy.assignment_policy_inboxes.where.not(inbox_id: inbox_ids).destroy_all

      inbox_ids.each do |inbox_id|
        @policy.assignment_policy_inboxes.find_or_create_by!(
          inbox_id: inbox_id,
          account: current_account
        )
      end
    end

    def policy_params
      permitted = params.require(:assignment_policy).permit(
        :name, :description, :strategy, :status, :position,
        :max_conversations_per_agent,
        :respect_business_hours, :business_hour_group_id,
        :reassign_on_offline, :idle_timeout_minutes,
        :prioritize_by_conversation_priority,
        :consider_agent_skills, :allow_idle_reassignment,
        :notify_on_assignment, :notify_team_leads,
        :conditions
      )

      # Parse conditions JSON string from hidden field
      permitted[:conditions] = parse_json(permitted[:conditions]) if permitted[:conditions].is_a?(String)

      # Handle configurations for skills-based strategy
      if params.dig(:assignment_policy, :configurations).present?
        configurations = params.require(:assignment_policy).permit(
          configurations: [:skill_match_mode, :fallback_strategy, required_skill_ids: []]
        )
        permitted[:configurations] = configurations[:configurations] || {}
      end

      permitted
    end

    def parse_json(value)
      JSON.parse(value)
    rescue JSON::ParserError
      {}
    end
  end
end
