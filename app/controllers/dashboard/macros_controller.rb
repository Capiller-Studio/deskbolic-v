# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class MacrosController < DashboardController
    before_action :set_macro, only: [ :edit, :update, :destroy, :execute ]

    def index
      authorize(Macro)

      @macros = current_account.macros.for_user(current_user).order(:name)
    end

    def new
      @macro = current_account.macros.new(visibility: :account_wide)
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

      if @macro.update(macro_params)
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

    def execute
      authorize(@macro)

      conversation = current_account.conversations.find(params[:conversation_id])

      Automations::ExecutionWorker.perform_async(
        "Macro",
        @macro.id,
        "Conversation",
        conversation.id,
        "manual",
        0
      )

      respond_to do |format|
        format.turbo_stream { render(turbo_stream: turbo_stream.append("flash", partial: "shared/flash", locals: { type: :notice, message: t(".executed") })) }
        format.html { redirect_back(fallback_location: conversation_path(conversation), notice: t(".executed")) }
      end
    end

    private

    def set_macro
      @macro = current_account.macros.find(params[:id])
    end

    def macro_params
      permitted = params.expect(macro: [
        :name, :description, :status, :visibility,
        { actions: [] }
      ])

      # Hidden field sends JSON string — parse into array
      permitted[:actions] = parse_json(permitted[:actions]) if permitted[:actions].is_a?(String)

      permitted
    end

    def assign_scopeable!(macro)
      case macro.visibility
      when "personal"
        macro.scopeable = current_user
      when "team"
        macro.scopeable = current_account.teams.find(params.dig(:macro, :team_id)) if params.dig(:macro, :team_id).present?
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
