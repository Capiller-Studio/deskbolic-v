# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Dashboard
  class MacrosController < DashboardController
    before_action :set_macro, only: [ :edit, :update, :destroy, :toggle, :execute ]

    def index
      authorize(Macro)

      macros = Macro.visible_to(current_user, current_account).order(:name)
      macros = macros.where(visibility: params[:visibility]) if params[:visibility].present?
      macros = macros.where(status: params[:status]) if params[:status].present?

      if params[:q].present?
        q = "%#{params[:q].to_s.strip}%"
        macros = macros.where("name ILIKE :q OR description ILIKE :q", q: q)
      end

      @per_page = [ 10, 20, 50 ].include?(params[:per_page].to_i) ? params[:per_page].to_i : 10
      @pagy, @macros = pagy(macros, items: @per_page)
    end

    def new
      @macro = current_account.macros.new(visibility: :account_wide, status: :active)
      authorize(@macro)
    end

    def edit
      authorize(@macro)
    end

    def create
      @macro = current_account.macros.new(macro_params)
      assign_scopeable!(@macro)
      authorize(@macro)

      if @macro.save
        redirect_to(macros_path, notice: t(".created"))
      else
        render(:new, status: :unprocessable_entity)
      end
    end

    def update
      authorize(@macro)
      @macro.assign_attributes(macro_params)
      assign_scopeable!(@macro)

      if @macro.save
        redirect_to(macros_path, notice: t(".updated"))
      else
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      authorize(@macro)
      @macro.destroy!

      respond_to do |format|
        format.turbo_stream { render(turbo_stream: turbo_stream.remove("macro_#{@macro.id}")) }
        format.html { redirect_to(macros_path, notice: t(".destroyed")) }
      end
    end

    def toggle
      authorize(@macro, :toggle?)
      @macro.toggle!

      respond_to do |format|
        format.turbo_stream do
          render(turbo_stream: turbo_stream.replace(
            "macro_#{@macro.id}",
            partial: "dashboard/macros/macro_row",
            locals: { macro: @macro }
          ))
        end
        format.html { redirect_to(macros_path) }
      end
    end

    # GET /macros/available?conversation_id=...&q=...
    # Returns executable macros available to the current agent for the conversation macro picker.
    def available
      authorize(Macro, :available?)

      macros = Macro.visible_to(current_user, current_account).executable.order(:name)

      if params[:q].present?
        q = "%#{params[:q].to_s.strip}%"
        macros = macros.where("name ILIKE :q OR description ILIKE :q", q: q)
      end

      @macros = macros.limit(30)
      @conversation = current_account.conversations.find_by(id: params[:conversation_id])

      respond_to do |format|
        format.html do
          render(partial: "dashboard/conversations/macros/list", locals: { macros: @macros, conversation: @conversation }, layout: false)
        end
        format.json do
          render(json: {
            macros: @macros.map do |m|
              {
                id: m.id,
                name: m.name,
                description: m.description,
                visibility: m.visibility,
                actions: m.actions,
                actions_count: m.actions.size
              }
            end
          })
        end
      end
    end

    def execute
      authorize(@macro, :execute?)

      @conversation = current_account.conversations.find(params[:conversation_id])
      result = Macros::Executor.call(macro: @macro, conversation: @conversation, actor: current_user)
      @conversation.reload

      notice_type = result.failed? ? :alert : :notice
      message = if result.success?
                  t(".executed", name: @macro.name, default: "Macro '%{name}' executed successfully.")
      elsif result.partial?
                  t(".partially_executed", name: @macro.name, default: "Macro '%{name}' executed with some errors.")
      else
                  t(".failed", name: @macro.name, default: "Failed to execute macro '%{name}'.")
      end

      respond_to do |format|
        format.turbo_stream do
          streams = []
          streams << turbo_stream.append("flash-messages", partial: "shared/flash", locals: { type: notice_type, message: message })

          streams << turbo_stream.replace(
            "conversation-details-#{@conversation.id}",
            partial: "dashboard/conversations/conversation_details",
            locals: { conversation: @conversation, assigned_team: @conversation.team }
          )

          streams << turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@conversation),
            partial: "dashboard/conversations/conversation",
            locals: { conversation: @conversation }
          )

          render(turbo_stream: streams)
        end
        format.json do
          render(json: {
            success: result.success?,
            partial: result.partial?,
            status: result.status,
            message: message,
            results: result.results
          }, status: result.failed? ? :unprocessable_entity : :ok)
        end
        format.html do
          flash[notice_type] = message
          redirect_back(fallback_location: conversation_path(@conversation))
        end
      end
    end

    private

    def set_macro
      @macro = current_account.macros.find(params[:id])
    end

    def macro_params
      raw_macro = params[:macro] || ActionController::Parameters.new
      raw_actions = raw_macro[:actions]

      permitted = params.expect(macro: [
        :name, :description, :status, :visibility
      ])

      if raw_macro.key?(:actions)
        parsed_actions = case raw_actions
        when String
                           parse_json(raw_actions)
        when Array
                           raw_actions.map { |a| a.respond_to?(:to_unsafe_h) ? a.to_unsafe_h : a }
        else
                           []
        end

        permitted[:actions] = parsed_actions
      end

      permitted
    end

    def assign_scopeable!(macro)
      case macro.visibility.to_s
      when "personal"
        macro.scopeable = current_user
      when "team"
        team_id = params.dig(:macro, :team_id).presence
        macro.scopeable = team_id ? current_account.teams.find_by(id: team_id) : nil
      else
        macro.scopeable = nil
      end
    end

    def parse_json(value)
      JSON.parse(value)
    rescue JSON::ParserError
      []
    end
  end
end
