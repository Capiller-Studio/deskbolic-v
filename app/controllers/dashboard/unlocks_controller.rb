# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Dashboard
  class UnlocksController < Devise::UnlocksController
    layout "auth"

    prepend_before_action :sign_out_if_unlocking, only: :show

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    private

    def sign_out_if_unlocking
      return if params[:unlock_token].blank?

      sign_out(:user) if user_signed_in?
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
