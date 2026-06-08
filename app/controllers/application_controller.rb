# frozen_string_literal: true

class ApplicationController < ActionController::Base
  around_action :switch_locale

  def switch_locale(&action)
    requested_locale = params[:locale]&.to_s
    
    locale_to_set = if requested_locale.blank?
      I18n.default_locale
    elsif Core::SUPPORTED_LOCALES.map(&:to_s).include?(requested_locale)
      requested_locale
    else
      nil
    end

    if locale_to_set
      I18n.with_locale(locale_to_set, &action)
    else
      redirect_to url_for(params.to_unsafe_h.merge(locale: nil, only_path: true)), status: :moved_permanently
    end
  end

  def default_url_options
    if I18n.locale.to_s != I18n.default_locale.to_s
      { locale: I18n.locale }
    else
      { locale: nil }
    end
  end
end
