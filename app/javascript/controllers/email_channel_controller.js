import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "smtpResult", "imapResult", "forwardEmail",
    "smtpSection", "imapSection", "passwordField",
    "smtpTestBtn", "imapTestBtn", "verifyBtn"
  ]

  // ─── Copy forward email to clipboard ───
  copyForwardEmail(event) {
    const btn = event.currentTarget
    const email = btn.dataset.email || this.forwardEmailTarget.textContent.trim()

    navigator.clipboard.writeText(email).then(() => {
      const originalText = btn.innerHTML
      btn.innerHTML = "✓ Copied!"
      btn.classList.add("channel-copy-btn--copied")

      setTimeout(() => {
        btn.innerHTML = originalText
        btn.classList.remove("channel-copy-btn--copied")
      }, 2000)
    })
  }

  // ─── Toggle collapsible sections ───
  toggleSection(event) {
    const section = event.currentTarget.closest(".channel-section")
    section.classList.toggle("channel-section--open")
  }

  // ─── Toggle password visibility ───
  togglePassword(event) {
    const btn = event.currentTarget
    const wrapper = btn.closest(".channel-password-wrapper")
    const input = wrapper.querySelector("input")

    if (input.type === "password") {
      input.type = "text"
      btn.textContent = "🙈"
    } else {
      input.type = "password"
      btn.textContent = "👁️"
    }
  }

  // ─── Test SMTP Connection ───
  async testSmtp(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const url = btn.dataset.url
    const form = btn.closest("form") || this.element.querySelector("form")

    this._setTestState(btn, this.smtpResultTarget, "testing")

    try {
      const formData = new FormData(form)
      formData.delete("_method")
      
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this._csrfToken(),
          "Accept": "application/json"
        },
        body: formData
      })

      const data = await response.json()
      if (data.success) {
        this._setTestState(btn, this.smtpResultTarget, "success", data.message)
      } else {
        this._setTestState(btn, this.smtpResultTarget, "error", data.message || data.error)
      }
    } catch (err) {
      this._setTestState(btn, this.smtpResultTarget, "error", err.message)
    }
  }

  // ─── Test IMAP Connection ───
  async testImap(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const url = btn.dataset.url
    const form = btn.closest("form") || this.element.querySelector("form")

    this._setTestState(btn, this.imapResultTarget, "testing")

    try {
      const formData = new FormData(form)
      formData.delete("_method")
      
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this._csrfToken(),
          "Accept": "application/json"
        },
        body: formData
      })

      const data = await response.json()
      if (data.success) {
        this._setTestState(btn, this.imapResultTarget, "success", data.message)
      } else {
        this._setTestState(btn, this.imapResultTarget, "error", data.message || data.error)
      }
    } catch (err) {
      this._setTestState(btn, this.imapResultTarget, "error", err.message)
    }
  }

  // ─── Verify Forwarding ───
  async verifyForwarding(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const url = btn.dataset.url

    btn.disabled = true
    btn.innerHTML = '<span class="channel-spinner"></span> Sending verification...'

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this._csrfToken(),
          "Accept": "application/json"
        }
      })

      const data = await response.json()
      if (data.success) {
        btn.innerHTML = "✓ Verification email sent!"
        btn.classList.add("channel-copy-btn--copied")
      } else {
        btn.innerHTML = "✗ " + (data.error || "Failed to send")
        btn.disabled = false
      }
    } catch (err) {
      btn.innerHTML = "✗ " + err.message
      btn.disabled = false
    }
  }

  // ─── Forwarding instruction tabs ───
  selectTab(event) {
    const tabName = event.currentTarget.dataset.tab
    const container = event.currentTarget.closest(".channel-forwarding-panel") || this.element

    // Update tab buttons
    container.querySelectorAll(".channel-tab").forEach(tab => {
      tab.classList.toggle("channel-tab--active", tab.dataset.tab === tabName)
    })

    // Update tab content
    container.querySelectorAll(".channel-tab-content").forEach(content => {
      content.classList.toggle("channel-tab-content--active", content.dataset.tabContent === tabName)
    })
  }

  // ─── Private helpers ───

  _setTestState(btn, resultTarget, state, message = "") {
    switch (state) {
      case "testing":
        btn.disabled = true
        btn.innerHTML = '<span class="channel-spinner"></span> Testing...'
        resultTarget.style.display = "none"
        break

      case "success":
        btn.disabled = false
        btn.innerHTML = btn.dataset.originalText || "Test"
        resultTarget.style.display = "inline-flex"
        resultTarget.className = "channel-test-result ec-test-result--success"
        resultTarget.innerHTML = `✓ ${message || "Connection successful!"}`
        break

      case "error":
        btn.disabled = false
        btn.innerHTML = btn.dataset.originalText || "Test"
        resultTarget.style.display = "inline-flex"
        resultTarget.className = "channel-test-result ec-test-result--error"
        resultTarget.innerHTML = `✗ ${message || "Connection failed"}`
        break
    }
  }

  _csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
