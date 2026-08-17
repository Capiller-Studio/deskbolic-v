# frozen_string_literal: true

module Dashboard
  class ProfileController < DashboardController
    def index
      @user = current_user
      @address = @user.address
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
