# frozen_string_literal: true

module Dashboard
  class WorkspaceController < DashboardController
    def new
      @account   = Account.new
      @accounts  = Account.all
    end

    def create
      params[:user_type] == "agent" ? workspace_request : new_workspace
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
        currency: params[:currency].presence || "USD",
        locale: params[:account_locale].presence || I18n.locale,
        shard_key: params[:shard_key].presence || "de",
        timezone: params[:timezone].presence || "UTC",
        data: { "company-name" => params[:company_name], "workspace-size" => params[:workspace_size] }
      )

      unless account.save
        redirect_to(workspace_path, alert: account.errors.full_messages.join(", ")) and return
      end

      account.users << current_user
      session[:current_account_id] = account.id
      cookies.signed[:current_account_id] = { value: account.id, expires: 1.year.from_now }
      redirect_to(submitted_path(current_user.id), notice: "New WorkSpace Created Successfully")
    end

     def submitted; end
  end
end
