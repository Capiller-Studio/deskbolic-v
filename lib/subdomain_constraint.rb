# frozen_string_literal: true

class SubdomainConstraint
  def self.matches?(request)
    return true if CapillerHost.app_host?(request.host)

    CapillerHost.tenant_subdomain?(request.subdomain)
  end
end
