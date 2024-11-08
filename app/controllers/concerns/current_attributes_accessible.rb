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
  end
  
  def configure_account
    Current.account ? Current.account : current_user&.accounts&.order(:created_at)&.first   
  end
end
