# frozen_string_literal: true

module Dashboard
  class AccountInvitationsController < DashboardController
    skip_before_action :authenticate_user!, only: %i[email_invitation accept_invitation]
    skip_before_action :ensure_subdomain_for_account, only: %i[email_invitation accept_invitation]
    skip_before_action :redirect_if_no_accounts, only: %i[email_invitation accept_invitation]
    skip_before_action :enforce_active_subscription, only: %i[email_invitation accept_invitation]
    skip_before_action :set_unread_counts, only: %i[email_invitation accept_invitation]
    skip_around_action :set_sharding_context, only: %i[email_invitation accept_invitation]

    layout "auth", only: %i[email_invitation accept_invitation]

    def index
      @invitations = current_account.account_invitations.pending.includes(:invited_by)
      role_ids = @invitations.flat_map(&:role_ids).uniq
      @invitation_roles_by_id = ::Access::Role.where(id: role_ids).index_by { |role| role.id.to_s }
    end

    def new
      @invitation = current_account.account_invitations.new
    end

    def create
      service = Accounts::Invitations::Create.new(
        account: current_account,
        invited_by: current_user,
        email: params[:email],
        role_ids: params[:role_ids].to_a.compact_blank
      )

      begin
        service.call
        redirect_to(invitations_path, notice: I18n.t("dashboard.invitations.create.success", default: "Invitation sent successfully."))
      rescue StandardError => e
        redirect_to(new_invitation_path, alert: e.message)
      end
    end

    def destroy
      @invitation = current_account.account_invitations.find(params[:id])
      @invitation.update!(status: :revoked)

      redirect_to(invitations_path, notice: I18n.t("dashboard.invitations.destroy.success", default: "Invitation revoked."))
    end

    def email_invitation
      find_invitation
      return if performed?

      @account = @invitation.account
      @role_names = @account.with_shard do
        ::Access::Role.where(id: @invitation.role_ids).pluck(:name)
      end
      @existing_user = User.find_by(email: @invitation.email)
    end

    def accept_invitation
      find_invitation
      return if performed?

      user = User.find_by(email: @invitation.email)

      unless user
        user_params = params[:user] || params

        if user_params[:password].blank? || user_params[:password] != params[:confirm_password]
          render_invitation_error("Passwords do not match or cannot be blank.")
          return
        end

        user = User.new(
          email: @invitation.email,
          password: user_params[:password],
          first_name: user_params[:first_name],
          last_name: user_params[:last_name],
          locale: I18n.locale,
          address: Address.create!
        )
        user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
        user.save!
      end

      Accounts::Invitations::Accept.call(token: @invitation.token, user: user)
      set_session_and_redirect(user, @invitation.account)
    rescue ActiveRecord::RecordInvalid => e
      render_invitation_error(e.record.errors.full_messages.join(", "))
    rescue StandardError => e
      render_invitation_error(e.message)
    end

    private

    def find_invitation
      token = params[:token].presence || params[:invitation_token]
      @invitation = AccountInvitation.find_by(token: token)

      if @invitation.blank? || @invitation.expired? || @invitation.revoked?
        redirect_to(new_user_session_path, alert: t("accounts.invitations.errors.expired", default: "This invitation is invalid or has expired."))
        return
      end

      if @invitation.accepted?
        redirect_to(new_user_session_path, alert: t("accounts.invitations.errors.already_accepted", default: "This invitation has already been accepted. Please sign in."))
      end
    end

    def set_session_and_redirect(user, account)
      sign_out(current_user) if user_signed_in? && current_user != user
      sign_in(user)
      session[:current_account_id] = account.id
      cookies.signed[:current_account_id] = { value: account.id, expires: 1.year.from_now }
      redirect_to(root_url(subdomain: account.identifier), allow_other_host: true, status: :see_other, notice: "You've successfully joined the team!")
    end

    def render_invitation_error(message)
      @account = @invitation.account
      @role_names = @account.with_shard { ::Access::Role.where(id: @invitation.role_ids).pluck(:name) }
      @existing_user = User.find_by(email: @invitation.email)
      flash.now[:alert] = message
      render(:email_invitation, status: :unprocessable_entity)
    end
  end
end
