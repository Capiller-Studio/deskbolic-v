# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class PasswordsController < Devise::PasswordsController
    layout "auth"

    def update
      super do |resource|
        if resource.errors.empty? && resource.accounts.any?
          account_id = resource.accounts.first.id
          session[:current_account_id] = account_id
          cookies.signed[:current_account_id] = { value: account_id, expires: 1.year.from_now }
        end
      end
    end

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_resetting_password_path_for(resource)
      if resource.accounts.any?
        account = resource.accounts.first
        root_url(subdomain: account.identifier)
      else
        workspace_url(subdomain: "")
      end
    end

    def after_sending_reset_password_instructions_path_for(_resource_name)
      new_user_session_url(subdomain: "")
    end
  end
end
