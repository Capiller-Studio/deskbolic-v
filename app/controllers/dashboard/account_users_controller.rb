module Dashboard
  class AccountUsersController < DashboardController
    before_action :set_account_user, only: [:edit, :update, :destroy]

    def index
      @account_users = current_account.account_users.includes(:user, :roles)
    end

    def edit
    end

    def update
      if @account_user.owner?
        redirect_to users_path, alert: I18n.t("dashboard.users.update.owner_error", default: "You cannot modify the account owner's roles.")
        return
      end

      # Only process role assignment if role_ids are present
      if params[:account_user] && params[:account_user][:role_ids]
        @account_user.role_ids = params[:account_user][:role_ids].reject(&:blank?)
      end

      if @account_user.save
        redirect_to users_path, notice: I18n.t("dashboard.users.update.success", default: "User roles updated successfully.")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @account_user.user == current_user
        redirect_to users_path, alert: I18n.t("dashboard.users.destroy.self_error", default: "You cannot remove yourself from the account.")
        return
      end

      if @account_user.owner?
        redirect_to users_path, alert: I18n.t("dashboard.users.destroy.owner_error", default: "You cannot remove the account owner.")
        return
      end
      if @account_user.destroy
        redirect_to users_path, notice: I18n.t("dashboard.users.destroy.success", default: "User removed successfully.")
      else
        redirect_to users_path, alert: I18n.t("dashboard.users.destroy.error", default: "Failed to remove user.")
      end
    end

    private

    def set_account_user
      @account_user = current_account.account_users.find(params[:id])
    end
  end
end
