# frozen_string_literal: true

class Rack::Attack
  # Rate limits for login attempts (5 attempts per minute per email)
  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    if req.post? && req.path.match?(%r{\A(/[a-z]{2}(?:-[A-Za-z]{2,4})?)?/(login|users/sign_in)\z})
      # Normalize the email, using the same logic as your authentication process, to
      # protect against rate limit bypasses. Return the normalized email if present, nil otherwise.
      req.params["user"].try(:[], "email").to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Rate limits for login attempts by IP (20 attempts per minute per IP)
  throttle("logins/ip", limit: 20, period: 1.minute) do |req|
    if req.post? && req.path.match?(%r{\A(/[a-z]{2}(?:-[A-Za-z]{2,4})?)?/(login|users/sign_in)\z})
      req.ip
    end
  end

  # Rate limits for registration signups by IP (5 registrations per hour per IP)
  throttle("registrations/ip", limit: 5, period: 1.hour) do |req|
    if req.post? && req.params["user"].present? && req.path.match?(%r{\A(/[a-z]{2}(?:-[A-Za-z]{2,4})?)?/?\z})
      req.ip
    end
  end

  # Rate limits for sending test emails in the builder (3 per minute per user)
  throttle("email_templates/test_email", limit: 3, period: 1.minute) do |req|
    if req.path.include?("/send_test") && req.post?
      # Throttle by the signed-in user's session if possible, fallback to IP
      req.session["warden.user.user.key"] || req.ip
    end
  end

  # DNS Reputation & Spam Protection: Limit SMTP/IMAP/Forwarding testing
  throttle("channels/test_credentials", limit: 5, period: 1.minute) do |req|
    if req.post? && (req.path.include?("test_smtp") || req.path.include?("test_imap") || req.path.include?("verify_forwarding"))
      req.session["warden.user.user.key"] || req.ip
    end
  end

  # Webhook testing abuse protection
  throttle("channels/test_webhooks", limit: 10, period: 1.minute) do |req|
    if req.post? && (req.path.include?("test_outgoing_webhook") || req.path.include?("test_incoming_webhook"))
      req.session["warden.user.user.key"] || req.ip
    end
  end

  # Workspace creation spam protection (prevents bot farm signups)
  throttle("workspace/create", limit: 3, period: 1.hour) do |req|
    if req.path == "/workspace" && req.post?
      req.ip
    end
  end

  # Team invitations spam protection
  throttle("team/invitations", limit: 10, period: 1.minute) do |req|
    if req.post? && req.path.include?("/invite/")
      req.session["warden.user.user.key"] || req.ip
    end
  end

  # Password Reset Spam Protection (prevents email bombing)
  throttle("logins/password_reset", limit: 3, period: 1.minute) do |req|
    if req.post? && req.path.match?(%r{\A(/[a-z]{2}(?:-[A-Za-z]{2,4})?)?/(password|users/password)\z})
      req.ip
    end
  end

  # Billing Webhooks Abuse Protection (Stripe/Paddle)
  throttle("webhooks/billing", limit: 100, period: 1.minute) do |req|
    if req.post? && (req.path == "/stripe" || req.path == "/paddle")
      req.ip
    end
  end

  # DNS Verification Abuse Protection
  throttle("channels/verify_dns", limit: 5, period: 1.minute) do |req|
    if req.post? && req.path.include?("verify_dns")
      req.session["warden.user.user.key"] || req.ip
    end
  end

  # CSAT Survey Submissions
  throttle("csat/submissions", limit: 5, period: 1.minute) do |req|
    if req.post? && req.path.include?("csat_surveys")
      req.ip
    end
  end

  # SAML ACS endpoint — prevent assertion replay flooding
  throttle("auth/saml/consume", limit: 10, period: 1.minute) do |req|
    if req.post? && req.path.include?("/auth/saml/consume")
      req.ip
    end
  end

  # Domain lookup — prevent email domain enumeration
  throttle("auth/domain_lookup", limit: 30, period: 1.minute) do |req|
    if req.get? && req.path.include?("/auth/domain_lookup")
      req.ip
    end
  end

  # SSO initiate — prevent redirect loop abuse
  throttle("auth/saml/initiate", limit: 15, period: 1.minute) do |req|
    if req.get? && req.path.include?("/auth/saml/initiate")
      req.ip
    end
  end

  # SCIM 2.0 API — directory sync rate limiting
  throttle("scim/api", limit: 120, period: 1.minute) do |req|
    if req.path.start_with?("/api/scim/v2")
      req.ip
    end
  end

  # Send a 429 response when throttled
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - (now % match_data[:period]))).to_s,
      "Content-Type" => "application/json"
    }

    [ 429, headers, [ { error: "Too many requests. Please try again later." }.to_json ] ]
  end
end
