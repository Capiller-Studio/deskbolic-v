# frozen_string_literal: true

module Dashboard
  class ProfileController < DashboardController
    def index
      @user = current_user
      @address = @user.address
      @mobile_profile_counts = {
        assigned: current_account.conversations.where(status: :active, assignee: current_user).count,
        mentions: @unread_counts&.dig(:mentions).to_i,
        resolved: current_account.conversations.where(status: :resolved, updated_at: Time.zone.today.all_day).count
      }
    end

    def update
      ActiveRecord::Base.transaction do
        current_user.address ||= Address.create!
        current_user.address.update!(address_params)
        current_user.update!(profile_params)
      end

      redirect_to(profile_path, notice: "Profile updated successfully.")
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = "Unable to update profile. Please check the fields and try again."
      render(:index, status: :unprocessable_entity)
    end

    private

    def profile_params
      params.expect(user: [ :avatar, :name, :display_name, :status ])
    end

    def address_params
      params.fetch(:address, {}).permit(:city, :state_name, :phone_number, :designation, :organization_name)
    end
  end
end
