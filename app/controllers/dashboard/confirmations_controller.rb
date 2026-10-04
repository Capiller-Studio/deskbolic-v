# frozen_string_literal: true

module Dashboard
  class ConfirmationsController < Devise::ConfirmationsController
    layout "auth"

    prepend_before_action :sign_out_if_confirming, only: :show

    def redirect_to(options = {}, response_options = {})
      response_options[:allow_other_host] = true if options.is_a?(String) && options.match?(/\Ahttps?:\/\//)
      super(options, response_options)
    end

    private

    def sign_out_if_confirming
      return if params[:confirmation_token].blank?

      sign_out(:user) if user_signed_in?
    end

    protected

    def after_resending_confirmation_instructions_path_for(_resource_name)
      new_user_session_url(subdomain: "")
    end

    def after_confirmation_path_for(_resource_name, resource)
      if request.subdomain.present? && request.subdomain != "www"
        subdomain_account = Account.find_by(identifier: request.subdomain)
        if subdomain_account && resource.accounts.exists?(id: subdomain_account.id)
          return new_user_session_url(subdomain: subdomain_account.identifier)
        end
      end

      if resource.accounts.count == 1
        new_user_session_url(subdomain: resource.accounts.first.identifier)
      else
        new_user_session_url(subdomain: "")
      end
    end
  end
end
