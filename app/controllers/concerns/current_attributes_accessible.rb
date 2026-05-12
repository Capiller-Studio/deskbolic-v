# frozen_string_literal: true

module CurrentAttributesAccessible
  extend ActiveSupport::Concern

  included do
    before_action :configure_attributes
  end

  private

  def configure_attributes
    Current.user       = current_user
    Current.account    = configure_account
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
    Current.request_id = request.request_id
  end

  def configure_account
    Current.account ? Current.account : current_user&.accounts&.order(:created_at)&.first
  end
end
