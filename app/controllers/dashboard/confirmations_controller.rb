# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class ConfirmationsController < Devise::ConfirmationsController
    layout "auth"

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_resending_confirmation_instructions_path_for(_resource_name)
      new_user_session_url(subdomain: "")
    end

    def after_confirmation_path_for(_resource_name, resource)
      if resource.accounts.any?
        account = resource.accounts.first
        new_user_session_url(subdomain: account.identifier)
      else
        new_user_session_url(subdomain: "")
      end
    end
  end
end
