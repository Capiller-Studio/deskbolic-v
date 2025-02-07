# frozen_string_literal: true

class DashboardController < ActionController::Base
  before_action :authenticate_user!
  before_action :redirect_if_no_accounts

  include Pundit
  include CurrentAttributesAccessible

  layout "dashboard"

  helper_method :current_account

  def pundit_user
    current_user
  end

  def current_account
    @current_account ||= current_user.accounts.find_by(id: session[:current_account_id])
  end

  def authorize(record, query = nil)
    super([ :dashboard, record ], query)
  end

  private

  def redirect_if_no_accounts
    if user_signed_in? && current_user.accounts.empty?
      redirect_to(workspace_path) unless request.path == workspace_path || request.path == submitted_path(current_user.id)
    end
  end
end
