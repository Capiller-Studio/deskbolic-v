# frozen_string_literal: true

module CapillerHost
  module_function

  def app_domain
    raw = ENV.fetch("APP_DOMAIN", "workspace.capiller.com")
    raw.sub(%r{\Ahttps?://}, "").split("/").first.to_s.split(":").first
  end

  def app_label
    app_domain.split(".").first
  end

  # Labels to the right of the leftmost host label. workspace.capiller.com => 2,
  # so Rails does not treat "workspace" as a tenant subdomain.
  def tld_length
    [ app_domain.split(".").length - 1, 0 ].max
  end

  def protocol
    Rails.env.production? ? "https" : "http"
  end

  def login_url
    "https://#{app_domain}/login"
  end

  def app_host?(host)
    host.to_s.split(":").first == app_domain
  end

  def tenant_subdomain?(subdomain)
    value = subdomain.to_s
    !value.empty? && value != "www" && value != app_label
  end
end
