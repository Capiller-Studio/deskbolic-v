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

      begin
        ActiveRecord::Base.transaction do
          account.save!
          create_owner_with_role!(account)
        end
      rescue ActiveRecord::RecordInvalid => e
        redirect_to(workspace_path, alert: e.record.errors.full_messages.join(", ")) and return
      end

      persist_selected_account(account)
      redirect_to(submitted_path(current_user.id), notice: "New WorkSpace Created Successfully")
    end

    def create_owner_with_role!(account)
      account_user = AccountUser.create!(account: account, user: current_user, owner: true)

      account.with_shard do
        owner_role = account.roles.find_by!(identifier: "owner")
        ::Access::AccountUserRole.create!(account: account, account_user_id: account_user.id, role: owner_role)
      end

      account_user
    end

     def submitted; end
  end
end
