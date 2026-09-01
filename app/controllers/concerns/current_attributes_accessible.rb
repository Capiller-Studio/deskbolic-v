# frozen_string_literal: true

module CurrentAttributesAccessible
  extend ActiveSupport::Concern

  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

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
    return @resolved_current_account if defined?(@resolved_current_account)

    @resolved_current_account =
      if user_signed_in?
        member_account || current_user.accounts.order(:created_at).first
      else
        account_from_subdomain
      end

    persist_selected_account(@resolved_current_account) if user_signed_in? && @resolved_current_account

    @resolved_current_account
  end

  def member_account
    selected = account_from_selection
    return selected if selected && current_user.accounts.exists?(selected.id)

    subdomain_account = account_from_subdomain
    subdomain_account if subdomain_account && current_user.accounts.exists?(subdomain_account.id)
  end

  def account_from_selection
    account_from_id(session[:current_account_id]) ||
      account_from_id(cookies.signed[:current_account_id])
  end

  def account_from_subdomain
    return if request.subdomain.blank? || request.subdomain == "www"

    Account.find_by(identifier: request.subdomain)
  end

  def account_from_id(id)
    return unless id.to_s.match?(UUID_FORMAT)

    Account.find_by(id: id)
  end

  def persist_selected_account(account)
    return if session[:current_account_id] == account.id && cookies.signed[:current_account_id] == account.id.to_s

    session[:current_account_id] = account.id
    cookies.signed[:current_account_id] = { value: account.id, expires: 1.year.from_now }
  end
end
