import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "protocolSelect",
    "statusSelect",
    "samlGroup",
    "oidcGroup",
    "errorBox",
    "entityIdInput",
    "ssoUrlInput",
    "certInput",
    "issuerInput",
    "clientIdInput",
    "clientSecretInput",
    "enforceSsoCheckbox",
    "domainsInput"
  ]

  static values = {
    hasCert: Boolean,
    hasSecret: Boolean
  }

  connect() {
    this.toggleProtocol()
  }

  toggleProtocol() {
    if (!this.hasProtocolSelectTarget) return

    const protocol = this.protocolSelectTarget.value
    if (this.hasSamlGroupTarget) {
      this.samlGroupTarget.style.display = protocol === "saml" ? "" : "none"
    }
    if (this.hasOidcGroupTarget) {
      this.oidcGroupTarget.style.display = protocol === "oidc" ? "" : "none"
    }
  }

  validate(event) {
    const errors = []
    const status = this.hasStatusSelectTarget ? this.statusSelectTarget.value : ""
    const protocol = this.hasProtocolSelectTarget ? this.protocolSelectTarget.value : "saml"
    const enforceSso = this.hasEnforceSsoCheckboxTarget ? this.enforceSsoCheckboxTarget.checked : false
    const domains = this.hasDomainsInputTarget ? this.domainsInputTarget.value.trim() : ""

    if (status === "active" || status === "test_mode") {
      if (protocol === "saml") {
        const entityId = this.hasEntityIdInputTarget ? this.entityIdInputTarget.value.trim() : ""
        const ssoUrl = this.hasSsoUrlInputTarget ? this.ssoUrlInputTarget.value.trim() : ""
        const cert = this.hasCertInputTarget ? this.certInputTarget.value.trim() : ""

        if (!entityId) {
          errors.push("Identity Provider Entity ID / Issuer URL is required when SSO is active or in test mode.")
        }
        if (!ssoUrl) {
          errors.push("Single Sign-On (SSO) URL is required when SSO is active or in test mode.")
        } else if (!/^https?:\/\//i.test(ssoUrl)) {
          errors.push("Single Sign-On (SSO) URL must start with http:// or https://")
        }
        if (!cert && !this.hasCertValue) {
          errors.push("At least one X.509 PEM certificate is required when SSO is active or in test mode.")
        }
      } else if (protocol === "oidc") {
        const issuer = this.hasIssuerInputTarget ? this.issuerInputTarget.value.trim() : ""
        const clientId = this.hasClientIdInputTarget ? this.clientIdInputTarget.value.trim() : ""
        const clientSecret = this.hasClientSecretInputTarget ? this.clientSecretInputTarget.value.trim() : ""

        if (!issuer) {
          errors.push("OIDC Issuer / Discovery URL is required when SSO is active or in test mode.")
        } else if (!/^https?:\/\//i.test(issuer)) {
          errors.push("OIDC Issuer URL must start with http:// or https://")
        }
        if (!clientId) {
          errors.push("OIDC Client ID is required when SSO is active or in test mode.")
        }
        if (!clientSecret && !this.hasSecretValue) {
          errors.push("OIDC Client Secret is required when configuring OIDC.")
        }
      }
    }

    if (enforceSso) {
      if (status !== "active") {
        errors.push("SSO Operating Status must be set to 'Active' before enforcing SSO for workspace members.")
      }
      if (!domains) {
        errors.push("Allowed Email Domains must be specified before enforcing SSO.")
      }
    }

    if (errors.length > 0) {
      event.preventDefault()
      event.stopPropagation()
      if (this.hasErrorBoxTarget) {
        this.errorBoxTarget.innerHTML = errors.map(msg => `<div>• ${msg}</div>`).join("")
        this.errorBoxTarget.style.display = "block"
        this.errorBoxTarget.scrollIntoView({ behavior: "smooth", block: "center" })
      }
    } else if (this.hasErrorBoxTarget) {
      this.errorBoxTarget.style.display = "none"
    }
  }
}
