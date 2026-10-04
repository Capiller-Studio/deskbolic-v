# frozen_string_literal: true

module SsoSessionGovernable
  extend ActiveSupport::Concern

  included do
    before_action :enforce_sso_session_timeout
  end

  private

  def enforce_sso_session_timeout
    return unless user_signed_in?
    return if session[:sso_signed_in_at].blank? || session[:sso_timeout_hours].blank?

    timeout_seconds = session[:sso_timeout_hours].to_i.hours.to_i
    return if timeout_seconds <= 0

    elapsed_time = Time.current.to_i - session[:sso_signed_in_at].to_i
    if elapsed_time > timeout_seconds
      account = current_account || Account.find_by(id: session[:sso_account_id])
      Auth::AuditLog.log(
        event_type:    :logout,
        auth_method:   :saml,
        status:        :success,
        account:       account,
        user:          current_user,
        metadata:      { reason: "session_timeout_expired" }
      )

      sign_out(current_user)
      reset_session
      redirect_to(new_user_session_path, alert: I18n.t("auth.sso.session_expired", default: "Your Single Sign-On session has expired. Please sign in again."))
    end
  end
end
