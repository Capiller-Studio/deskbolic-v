# frozen_string_literal: true

module Dashboard
  class SlaPoliciesController < DashboardController
    before_action :set_policy, only: [ :show, :edit, :update, :destroy ]

    def index
      # authorize(SlaPolicy)
      @policies = current_account.sla_policies.includes(:inboxes).order(created_at: :desc)
    end

    def show
      # authorize(@policy)
    end

    def new
      @policy = current_account.sla_policies.new
      # authorize(@policy)
      load_form_data
    end

    def edit
      # authorize(@policy)
      load_form_data
    end
    def create
      @policy = current_account.sla_policies.new(policy_params)
      # authorize(@policy)

      if @policy.save
        sync_inboxes
        redirect_to(sla_policies_path, notice: t(".created", default: "SLA Policy created successfully"))
      else
        load_form_data
        render(:new, status: :unprocessable_entity)
      end
    end


    def update
      # authorize(@policy)

      if @policy.update(policy_params)
        sync_inboxes
        redirect_to(sla_policies_path, notice: t(".updated", default: "SLA Policy updated successfully"))
      else
        load_form_data
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      # authorize(@policy)
      @policy.destroy!

      respond_to do |format|
        format.turbo_stream { render(turbo_stream: turbo_stream.remove("sla_policy_#{@policy.id}")) }
        format.html { redirect_to(sla_policies_path, notice: t(".destroyed", default: "SLA Policy destroyed")) }
      end
    end

    private

    def set_policy
      @policy = current_account.sla_policies.find(params[:id])
    end

    def load_form_data
      @inboxes = current_account.inboxes.order(:name)
      @business_hour_groups = current_account.business_hour_groups.order(:name)
    end

    def sync_inboxes
      inbox_ids = params.dig(:sla_policy, :inbox_ids)&.reject(&:blank?) || []
      @policy.sla_inboxes.where.not(inbox_id: inbox_ids).destroy_all

      inbox_ids.each do |inbox_id|
        @policy.sla_inboxes.find_or_create_by!(
          inbox_id: inbox_id,
          account: current_account
        )
      end
    end

    def policy_params
      permitted = params.expect(
        sla_policy: [ :name, :description,
        :during_working_hours, :business_hour_group_id ]
      )

      # Parse combined time inputs into seconds
      permitted[:initial_response_time_limit] = parse_time(params.dig(:sla_policy, :initial_response_value), params.dig(:sla_policy, :initial_response_unit))
      permitted[:response_time_limit] = parse_time(params.dig(:sla_policy, :response_value), params.dig(:sla_policy, :response_unit))
      permitted[:resolution_time_limit] = parse_time(params.dig(:sla_policy, :resolution_value), params.dig(:sla_policy, :resolution_unit))

      # For custom conditions JSON (similar to assignment policies)
      permitted[:configurations] = parse_json(params.dig(:sla_policy, :configurations)) if params.dig(:sla_policy, :configurations).present?

      permitted
    end

    def parse_time(value, unit)
      return nil if value.blank? || unit.blank?

      val = value.to_f
      case unit
      when "minutes" then val * 60
      when "hours" then val * 3600
      when "days" then val * 86400
      else val
      end
    end

    def parse_json(value)
      value.is_a?(String) ? JSON.parse(value) : value
    rescue JSON::ParserError
      {}
    end
  end
end
