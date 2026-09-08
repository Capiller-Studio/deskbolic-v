# frozen_string_literal: true

module Dashboard
  class ProfileController < DashboardController
    def index
      @user = current_user
      @address = @user.address
      @mobile_profile_counts = {
        assigned: current_account ? current_account.conversations.where(status: :active, assignee: current_user).count : 0,
        mentions: @unread_counts&.dig(:mentions).to_i,
        resolved: current_account ? current_account.conversations.where(status: :resolved, updated_at: Time.zone.today.all_day).count : 0
      }
    end

    def update
      ActiveRecord::Base.transaction do
        current_user.address ||= Address.create!
        current_user.address.update!(address_params)
        current_user.update!(profile_params)
      end

      redirect_to(profile_path, notice: t("dashboard.profile.index.notices.updated", default: "Profile updated successfully."))
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = t("dashboard.profile.index.alerts.update_failed", default: "Unable to update profile. Please check the fields and try again.")
      render(:index, status: :unprocessable_entity)
    end

    def destroy
      unless current_user.can_be_deleted?
        redirect_to(
          profile_path,
          alert: t("dashboard.profile.index.alerts.sole_owner", default: "You are the owner of an active workspace. You must transfer ownership or delete the workspace before deleting your personal account.")
        ) and return
      end

      unless current_user.valid_password?(params[:password])
        redirect_to(profile_path, alert: t("dashboard.profile.index.alerts.incorrect_password", default: "Incorrect password. Account deletion could not be processed.")) and return
      end

      user_to_delete = current_user
      user_to_delete.deactivate_for_deletion!
      target_acc = current_account || user_to_delete.accounts.first
      Activities::Recorder.call(trackable: user_to_delete, event_type: :deletion_requested, actor: user_to_delete, account: target_acc)

      sign_out(user_to_delete)
      redirect_to(
        new_user_session_path,
        notice: t("dashboard.profile.index.notices.deletion_requested", default: "Your account deletion request has been submitted. Your profile has been deactivated and will be permanently removed after review.")
      )
    end

    private

    def profile_params
      params.expect(user: [ :avatar, :name, :display_name ])
    end

    def address_params
      params.fetch(:address, {}).permit(:city, :state_name, :phone_number, :designation, :organization_name)
    end
  end
end
