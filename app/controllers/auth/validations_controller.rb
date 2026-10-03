# frozen_string_literal: true

module Auth
  class ValidationsController < ApplicationController
    protect_from_forgery with: :null_session, if: -> { request.format.json? }

    def check_email
      email = params[:email].to_s.strip.downcase

      if email.blank?
        render(json: { exists: false, valid: false, error: I18n.t("auth.email_required", default: "Email is required") })
      else
        exists = User.exists?(email: email)
        render(json: { exists: exists, valid: !exists })
      end
    end

    def check_identifier
      raw_value = params[:identifier].to_s.strip
      slug = raw_value.parameterize.tr("_", "-").downcase

      if slug.blank?
        render(json: { valid: false, error: I18n.t("auth.identifier_required", default: "Workspace identifier is required") })
      elsif slug.length < 3
        render(json: { valid: false, error: I18n.t("auth.identifier_too_short", default: "Workspace identifier must be at least 3 characters") })
      elsif slug.length > 63
        render(json: { valid: false, error: I18n.t("auth.identifier_too_long", default: "Workspace identifier cannot exceed 63 characters") })
      elsif Account::RESERVED_IDENTIFIERS.include?(slug)
        render(json: { valid: false, error: I18n.t("auth.identifier_reserved", slug: slug, default: "Workspace identifier '#{slug}' is a reserved word and cannot be used") })
      elsif Account.exists?(identifier: slug)
        render(json: { valid: false, error: I18n.t("auth.identifier_taken", slug: slug, default: "Workspace identifier '#{slug}' is already taken") })
      else
        render(json: { valid: true, slug: slug })
      end
    end
  end
end
