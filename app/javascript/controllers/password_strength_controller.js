import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["password", "confirmation", "strengthMeter", "matchStatus", "submitButton", "ruleLength", "ruleUpper", "ruleNumber", "ruleSpecial"]
  static classes = ["weak", "medium", "strong", "match", "mismatch"]
  static values = {
    matchMessage: { type: String, default: "Passwords match" },
    mismatchMessage: { type: String, default: "Passwords do not match" }
  }

  connect() {
    this.validatePassword()
    this.validateConfirmation()
  }

  validatePassword() {
    if (!this.hasPasswordTarget) return
    const val = this.passwordTarget.value
    let strength = 0

    const hasLength = val.length >= 8
    const hasUpper = /[A-Z]/.test(val)
    const hasLower = /[a-z]/.test(val)
    const hasNumber = /[0-9]/.test(val)
    const hasSpecial = /[^A-Za-z0-9]/.test(val)

    if (hasLength) strength += 1
    if (hasUpper) strength += 1
    if (hasLower) strength += 1
    if (hasNumber) strength += 1
    if (hasSpecial) strength += 1

    if (this.hasRuleLengthTarget) {
      this.ruleLengthTarget.style.color = hasLength ? "#10b981" : "#9ca3af"
    }
    if (this.hasRuleUpperTarget) {
      this.ruleUpperTarget.style.color = hasUpper ? "#10b981" : "#9ca3af"
    }
    if (this.hasRuleNumberTarget) {
      this.ruleNumberTarget.style.color = hasNumber ? "#10b981" : "#9ca3af"
    }
    if (this.hasRuleSpecialTarget) {
      this.ruleSpecialTarget.style.color = hasSpecial ? "#10b981" : "#9ca3af"
    }

    this.updateStrengthMeter(strength)
    this.checkReady()
  }

  validateConfirmation() {
    if (!this.hasConfirmationTarget || !this.hasPasswordTarget) return
    const pass = this.passwordTarget.value
    const conf = this.confirmationTarget.value

    if (conf.length === 0) {
      if (this.hasMatchStatusTarget) this.matchStatusTarget.textContent = ""
      this.checkReady()
      return
    }

    if (pass === conf) {
      if (this.hasMatchStatusTarget) {
        this.matchStatusTarget.textContent = this.matchMessageValue
        this.matchStatusTarget.style.color = "#10b981"
      }
    } else {
      if (this.hasMatchStatusTarget) {
        this.matchStatusTarget.textContent = this.mismatchMessageValue
        this.matchStatusTarget.style.color = "#ef4444"
      }
    }
    this.checkReady()
  }

  updateStrengthMeter(strength) {
    if (!this.hasStrengthMeterTarget) return
    
    if (strength === 0) {
      this.strengthMeterTarget.style.width = "0%"
    } else if (strength <= 2) {
      this.strengthMeterTarget.style.width = "33%"
      this.strengthMeterTarget.style.backgroundColor = "#ef4444" // red
    } else if (strength <= 4) {
      this.strengthMeterTarget.style.width = "66%"
      this.strengthMeterTarget.style.backgroundColor = "#f59e0b" // yellow
    } else {
      this.strengthMeterTarget.style.width = "100%"
      this.strengthMeterTarget.style.backgroundColor = "#10b981" // green
    }
  }

  checkReady() {
    if (!this.hasSubmitButtonTarget) return
    const pass = this.passwordTarget.value
    const conf = this.hasConfirmationTarget ? this.confirmationTarget.value : pass

    const hasLength = pass.length >= 8
    const hasUpper = /[A-Z]/.test(pass)
    const hasNumber = /[0-9]/.test(pass)
    const hasSpecial = /[^A-Za-z0-9]/.test(pass)
    const isValid = hasLength && hasUpper && hasNumber && hasSpecial

    if (isValid && pass === conf) {
      this.submitButtonTarget.removeAttribute("disabled")
      this.submitButtonTarget.style.opacity = "1"
      this.submitButtonTarget.style.cursor = "pointer"
    } else {
      this.submitButtonTarget.setAttribute("disabled", "true")
      this.submitButtonTarget.style.opacity = "0.5"
      this.submitButtonTarget.style.cursor = "not-allowed"
    }
  }
}
