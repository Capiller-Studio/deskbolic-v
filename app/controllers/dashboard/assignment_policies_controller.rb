# frozen_string_literal: true

module Dashboard
  class AssignmentPoliciesController < DashboardController
    before_action :set_policy, only: [ :show, :edit, :update, :destroy, :toggle ]

    def index
      authorize(AssignmentPolicy)

      policies_scope = current_account.assignment_policies
      strategy_counts = policies_scope.group(:strategy).count
      count_for_strategy = ->(strategy) { strategy_counts[strategy.to_s].to_i + strategy_counts[AssignmentPolicy.strategies[strategy.to_s]].to_i }
      @policy_counts = {
        all: policies_scope.count,
        round_robin: count_for_strategy.call(:round_robin),
        load_balanced: count_for_strategy.call(:load_balanced),
        skills_based: count_for_strategy.call(:skills_based),
        manual: count_for_strategy.call(:manual)
      }

      @policies = policies_scope.includes(:inboxes).order(:position)
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

    def edit
      authorize(@policy)
      load_form_data
    end
    def create
      @policy = current_account.assignment_policies.new(policy_params)
      authorize(@policy)

      if valid_assignment_policy?(@policy) && @policy.save
        sync_inboxes
        flash[:success] = t(".created")
        redirect_to(assignment_policies_path)
      else
        load_form_data
        render(:new, status: :unprocessable_entity)
      end
    end


    def update
      authorize(@policy)

      @policy.assign_attributes(policy_params)

      if valid_assignment_policy?(@policy) && @policy.save
        sync_inboxes
        flash[:success] = t(".updated")
        redirect_to(assignment_policies_path)
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

    def valid_assignment_policy?(policy)
      valid = policy.valid?

      if policy.respect_business_hours? && policy.business_hour_group_id.blank?
        policy.errors.add(:business_hour_group_id, :blank)
        valid = false
      end

      valid
    end

    def policy_params
      permitted = params.expect(
        assignment_policy: [ :name, :description, :strategy, :status, :position,
        :max_conversations_per_agent,
        :respect_business_hours, :business_hour_group_id,
        :reassign_on_offline, :idle_timeout_minutes,
        :prioritize_by_conversation_priority,
        :consider_agent_skills, :allow_idle_reassignment,
        :notify_on_assignment, :notify_team_leads,
        :conditions ]
      )

      # Parse conditions JSON string from hidden field
      permitted[:conditions] = parse_json(permitted[:conditions]) if permitted[:conditions].is_a?(String)

      # Handle configurations for skills-based strategy
      if params.dig(:assignment_policy, :configurations).present?
        configurations = params.expect(
          assignment_policy: [ configurations: [ :skill_match_mode, :fallback_strategy, required_skill_ids: [] ] ]
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
