# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class UnlocksController < Devise::UnlocksController
    layout "auth"

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    protected

    def after_sending_unlock_instructions_path_for(_resource)
      new_user_session_url(subdomain: "")
    end

    def after_unlock_path_for(_resource)
      new_user_session_url(subdomain: "")
    end
  end
end
