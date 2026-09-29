# frozen_string_literal: true

class ApplicationController < ActionController::Base
  REFERRAL_COOKIE = :ref
  SELECTED_PLAN_COOKIE = :selected_plan_id
  SELECTED_BILLING_CYCLE_COOKIE = :selected_billing_cycle
  SELECTED_CURRENCY_COOKIE = :currency

  before_action :persist_onboarding_params
  around_action :switch_locale

  def switch_locale(&)
    requested_locale = params[:locale]&.to_s

    locale_to_set = if requested_locale.blank?
      I18n.default_locale
    elsif Core::SUPPORTED_LOCALES.map(&:to_s).include?(requested_locale)
      requested_locale
    else
      nil
    end

    if locale_to_set
      I18n.with_locale(locale_to_set, &)
    else
      redirect_to(url_for(params.to_unsafe_h.merge(locale: nil, only_path: true)), status: :moved_permanently)
    end
  end

  def default_url_options
    if I18n.locale.to_s == I18n.default_locale.to_s
      { locale: nil }
    else
      { locale: I18n.locale }
    end
  end

  private

  def persist_onboarding_params
    persist_cookie(REFERRAL_COOKIE, params[:ref], expires: 14.days.from_now)
    persist_cookie(SELECTED_PLAN_COOKIE, params[:plan_id])
    persist_cookie(SELECTED_BILLING_CYCLE_COOKIE, params[:billing_cycle])
    persist_cookie(SELECTED_CURRENCY_COOKIE, params[:currency])
  end

  def persist_cookie(key, value, expires: 72.hours.from_now)
    value = value.to_s.strip
    return if value.blank?

    cookies[key] = {
      value: value,
      expires: expires,
      same_site: :lax
    }
  end
end
