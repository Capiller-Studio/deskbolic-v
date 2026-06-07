module Dashboard
  class AccountInvitationsController < DashboardController
    def index
      @invitations = current_account.account_invitations.pending
    end

    def new
      @invitation = current_account.account_invitations.new
    end

    def create
      service = Accounts::Invitations::Create.new(
        account: current_account,
        invited_by: current_user,
        email: params[:email],
        role_ids: params[:role_ids].to_a.reject(&:blank?)
      )

      begin
        service.call
        redirect_to invitations_path, notice: I18n.t("dashboard.invitations.create.success", default: "Invitation sent successfully.")
      rescue StandardError => e
        redirect_to new_invitation_path, alert: e.message
      end
    end

    def destroy
      @invitation = current_account.account_invitations.find(params[:id])
      @invitation.update!(status: :revoked)

      redirect_to invitations_path, notice: I18n.t("dashboard.invitations.destroy.success", default: "Invitation revoked.")
    end
  end
end
