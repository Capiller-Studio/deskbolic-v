# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class WorkspaceController < DashboardController
    skip_before_action :enforce_active_subscription, only: %i[index new create submitted activate]
    skip_around_action :set_sharding_context, only: %i[index new create submitted activate]

    layout "auth"

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    def index
      @accounts = current_user.accounts.order(:name)
      @account_users = current_user.account_users.index_by(&:account_id)
    end

    def new
      @account = Account.new
    end

    def create
      params[:user_type] == "agent" ? workspace_request : new_workspace
    end

    def submitted; end

    def activate
      account = current_user.accounts.active.find(params[:id])
      session[:account_id] = account.id
      redirect_to(root_url, status: :see_other)
    end

    private

    def workspace_request
      account = Account.find_by(email: params[:email])

      unless account
        redirect_to(workspace_path, alert: "No workspace found for that email.") and return
      end

      AdminNotificationMailer.workspace_request(account, current_user).deliver_now

      redirect_to(submitted_path(current_user.id), notice: "Request Sent")
    end

    def new_workspace
      account = Account.new(
        name: params[:account][:name],
        email: current_user.email,
        currency: "INR",
        locale: params[:account_locale].presence || I18n.locale,
        shard_key: "de",
        timezone: params[:timezone].presence || "UTC",
        data: { "company-name" => params[:company_name], "workspace-size" => params[:workspace_size] }
      )

      unless account.save
        redirect_to(workspace_path, alert: account.errors.full_messages.join(", ")) and return
      end

      account.account_users.create!(user: current_user, owner: true)

      session[:account_id] = account.id
      redirect_to(root_url, status: :see_other, notice: "New workspace created successfully")
    end
  end
end
