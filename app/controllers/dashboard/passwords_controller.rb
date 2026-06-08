# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class PasswordsController < Devise::PasswordsController
    layout "auth"
    # GET /resource/password/new
    # def new
    #   super
    # end

    # POST /resource/password
    # def create
    #   super
    # end

    # GET /resource/password/edit?reset_password_token=abcdef
    # def edit
    #   super
    # end

    # PUT /resource/password
    def update
      super do |resource|
        if resource.errors.empty? && resource.accounts.any?
          account_id = resource.accounts.first.id
          session[:current_account_id] = account_id
          cookies.signed[:current_account_id] = { value: account_id, expires: 1.year.from_now }
        end
      end
    end

    # protected

    # def after_resetting_password_path_for(resource)
    #   super(resource)
    # end

    # The path used after sending reset password instructions
    # def after_sending_reset_password_instructions_path_for(resource_name)
    #   super(resource_name)
    # end
  end
end
