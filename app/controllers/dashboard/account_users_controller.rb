module Dashboard
  class AccountUsersController < DashboardController
    before_action :set_account_user, only: [ :edit, :update, :destroy ]

    def index
      @account_users = current_account.account_users.includes(:roles, user: { avatar_attachment: :blob })
    end

    def search
      query = params[:q].to_s.strip.downcase
      @users = current_account.users.where("LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?", "%#{query}%", "%#{query}%", "%#{query}%").limit(10)
      render(json: @users.map { |u| { id: u.id, value: u.display_name, email: u.email } })
    end

    def edit
    end

    def update
      if params[:account_user] && params[:account_user][:role_ids]
        @account_user.assign_roles(params[:account_user][:role_ids])
        redirect_to(users_path, notice: I18n.t("dashboard.users.update.success", default: "User roles updated successfully."))
      else
        redirect_to(users_path, alert: I18n.t("dashboard.users.update.no_roles", default: "Please select at least one role."))
      end
    end

    def destroy
      if @account_user.owner?
        redirect_to(users_path, alert: I18n.t("dashboard.users.destroy.owner_error", default: "You cannot remove the account owner."))
        return
      end

      if @account_user.user == current_user
        redirect_to(users_path, alert: I18n.t("dashboard.users.destroy.self_error", default: "You cannot remove yourself from the account."))
        return
      end
      if @account_user.destroy
        redirect_to(users_path, notice: I18n.t("dashboard.users.destroy.success", default: "User removed successfully."))
      else
        redirect_to(users_path, alert: I18n.t("dashboard.users.destroy.error", default: "Failed to remove user."))
      end
    end

    private

    def set_account_user
      @account_user = current_account.account_users.find(params[:id])
    end
  end
end
