# frozen_string_literal: true

module Dashboard
  class WorkspaceController < DashboardController
    layout "auth", only: [:email_invitation, :accept_invitation]
    skip_before_action :authenticate_user!, :redirect_if_no_accounts, :enforce_active_subscription, only: [:email_invitation, :accept_invitation]
    skip_around_action :set_sharding_context, only: [:email_invitation, :accept_invitation]

    def new
      @account   = Account.new
      @accounts  = Account.all
    end

    def create
      params[:user_type] == "agent" ? workspace_request : new_workspace
    end

    def submitted; end

    def email_invitation
      find_invitation
      return if performed?

      @account = @invitation.account
      @role_names = @account.with_shard do
        ::Access::Role.where(id: @invitation.role_ids).pluck(:name)
      end
    end

    def accept_invitation
      find_invitation
      return if performed?

      user = User.find_by(email: @invitation.email)

      if user
        accept_existing_user(user)
      else
        accept_new_user
      end
    end

    private

    def find_invitation
      @invitation = AccountInvitation.find_by(token: params[:invitation_token])
      return if @invitation && !@invitation.expired?

      redirect_to new_user_session_path, alert: t("accounts.invitations.errors.expired", default: "This invitation is invalid or has expired.")
    end

    def set_session_and_redirect(user, account)
      sign_in(user)
      session[:current_account_id] = account.id
      cookies.signed[:current_account_id] = { value: account.id, expires: 1.year.from_now }
      redirect_to root_path, notice: "You've successfully joined the team!"
    end

    def workspace_request
      account = Account.find_by(email: params[:email])

      unless account
        redirect_to new_workspace_path, alert: "No workspace found for that email." and return
      end

      AdminNotificationMailer.workspace_request(account, current_user).deliver_now

      redirect_to(submitted_path(current_user.id), notice: "Request Sent")
    end

    def new_workspace
      account = Account.new(
        name: params[:account][:name],
        email: current_user.email,
        data: { "company-name" => params[:company_name], "workspace-size" => params[:workspace_size] }
      )

      unless account.save
        redirect_to new_workspace_path, alert: account.errors.full_messages.join(", ") and return
      end

      account.users << current_user
      session[:current_account_id] = account.id
      cookies.signed[:current_account_id] = { value: account.id, expires: 1.year.from_now }
      redirect_to(submitted_path(current_user.id), notice: "New WorkSpace Created Successfully")
    end

    def accept_existing_user(user)
      account = @invitation.account

      if account.users.exists?(id: user.id)
        redirect_to new_user_session_path, notice: "You are already a member of this team."
        return
      end

      ActiveRecord::Base.transaction do
        account_user = AccountUser.create!(account: account, user: user, owner: false)

        account.with_shard do
          @invitation.role_ids.each do |role_id|
            ::Access::AccountUserRole.create!(account: account, account_user_id: account_user.id, role_id: role_id)
          end
        end

        @invitation.update!(status: :accepted)
      end

      set_session_and_redirect(user, account)
    end

    def accept_new_user
      user_params = params[:user] || params

      if user_params[:password].blank? || user_params[:password] != params[:confirm_password]
        @account = @invitation.account
        @role_names = @account.with_shard { ::Access::Role.where(id: @invitation.role_ids).pluck(:name) }
        flash.now[:alert] = "Passwords do not match or cannot be blank."
        render :email_invitation, status: :unprocessable_entity
        return
      end

      result = Accounts::RegistrationService.call(
        email: @invitation.email,
        password: user_params[:password],
        first_name: user_params[:first_name],
        last_name: user_params[:last_name],
        invitation_token: @invitation.token,
        as_affiliate: false
      )

      if result.success?
        set_session_and_redirect(result.user, result.account)
      else
        @account = @invitation.account
        @role_names = @account.with_shard { ::Access::Role.where(id: @invitation.role_ids).pluck(:name) }
        flash.now[:alert] = result.errors.map { |e| e[:message] }.join(", ")
        render :email_invitation, status: :unprocessable_entity
      end
    end
  end
end
