# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class AutomationsController < DashboardController
    before_action :set_automation, only: [:show, :edit, :update, :destroy, :toggle, :duplicate]

    def index
      authorize(Automation)

      @automations = current_account.automations.order(:automation_type, :position)
      @automations = @automations.where(automation_type: params[:type]) if params[:type].present?
    end

    def show
      authorize(@automation)
    end

    def new
      @automation = current_account.automations.new(automation_type: params[:type] || :event_trigger)
      authorize(@automation)
    end

    def create
      @automation = current_account.automations.new(automation_params)
      authorize(@automation)

      if @automation.save
        current_account.increment_usage!(:automations)
        redirect_to(automations_path, notice: t(".created"))
      else
        render(:new, status: :unprocessable_entity)
      end
    end

    def edit
      authorize(@automation)
    end

    def update
      authorize(@automation)

      if @automation.update(automation_params)
        redirect_to(automations_path, notice: t(".updated"))
      else
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      authorize(@automation)
      @automation.destroy!
      current_account.decrement_usage!(:automations)

      respond_to do |format|
        format.turbo_stream { render(turbo_stream: turbo_stream.remove("automation_#{@automation.id}")) }
        format.html { redirect_to(automations_path, notice: t(".destroyed")) }
      end
    end

    def toggle
      authorize(@automation)
      @automation.toggle!

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.replace(
            "automation_#{@automation.id}",
            partial: "dashboard/automations/automation",
            locals: { automation: @automation }
          ))
        end
        format.html { redirect_to(automations_path) }
      end
    end

    def duplicate
      authorize(@automation)
      copy = @automation.duplicate
      copy.account = current_account

      if copy.save
        current_account.increment_usage!(:automations)
        redirect_to(edit_automation_path(copy), notice: t(".duplicated"))
      else
        redirect_to(automations_path, alert: t(".duplicate_failed"))
      end
    end

    def reorder
      authorize(Automation)
      Automation.reorder!(params[:ordered_ids])

      head(:ok)
    end

    # GET /automations/lookups?type=agents&q=sarah&page=1
    # Returns JSON for dynamic dropdowns in the builder.
    # Supports search (?q=) and pagination (?page=), max 20 per page.
    LOOKUP_LIMIT = 20

    def lookups
      authorize(Automation)

      page = [params[:page].to_i, 1].max
      offset = (page - 1) * LOOKUP_LIMIT

      scope = lookup_scope(params[:type])

      if scope.nil?
        render(json: { results: [], has_more: false })
        return
      end

      total = scope.count
      items = scope.offset(offset).limit(LOOKUP_LIMIT)

      results = items.map { |record| serialize_lookup(record, params[:type]) }

      render(json: {
        results: results,
        has_more: (offset + LOOKUP_LIMIT) < total,
        total: total,
        page: page
      })
    end

    private

    def lookup_scope(type)
      query = params[:q].to_s.strip
      search_filter = ->(scope, *columns) {
        return scope if query.blank?

        conditions = columns.map { |col| "#{col} ILIKE :q" }.join(" OR ")
        scope.where(conditions, q: "%#{query}%")
      }

      case type
      when "agents"
        search_filter.call(current_account.users, "first_name", "last_name", "email")
      when "teams"
        search_filter.call(current_account.teams, "name")
      when "inboxes"
        search_filter.call(current_account.inboxes, "name")
      when "labels"
        search_filter.call(current_account.labels, "title")
      end
    end

    def serialize_lookup(record, type)
      case type
      when "agents"
        { id: record.id, name: record.name.presence || record.email }
      when "teams"
        { id: record.id, name: record.name }
      when "inboxes"
        { id: record.id, name: record.name }
      when "labels"
        { id: record.id, name: record.title }
      end
    end

    def set_automation
      @automation = current_account.automations.find(params[:id])
    end

    def automation_params
      permitted = params.expect(automation: [
        :name, :description, :automation_type, :event_name, :status, :position,
        :conditions, :actions, { configurations: {} }
      ])

      # Hidden fields send JSON strings — parse them into hashes/arrays
      permitted[:conditions] = parse_json(permitted[:conditions]) if permitted[:conditions].is_a?(String)
      permitted[:actions] = parse_json(permitted[:actions]) if permitted[:actions].is_a?(String)

      permitted
    end

    def parse_json(value)
      JSON.parse(value)
    rescue JSON::ParserError
      {}
    end
  end
end
