import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "iframe",
    "launcher",
    "logoImg",
    "logoSvg"
  ]

  connect() {
    try {
      this.syncThemeColor()
      this.syncPosition()
      this.syncWelcomeTitle()
      this.syncWelcomeTagline()
      this.syncCustomFooterText()

      this.boundHandleInput = this.handleGlobalInput.bind(this)
      document.addEventListener('input', this.boundHandleInput)
      document.addEventListener('change', this.boundHandleInput)
    } catch (error) {
      console.error("Error during live preview initialization:", error)
    }
  }

  disconnect() {
    if (this.boundHandleInput) {
      document.removeEventListener('input', this.boundHandleInput)
      document.removeEventListener('change', this.boundHandleInput)
    }
  }

  handleGlobalInput(event) {
    const target = event.target
    if (!target || !target.name) return

    if (target.name.includes('[theme_color]')) {
      this.syncThemeColor(event)
    } else if (target.name.includes('[position]')) {
      this.syncPosition(event)
    } else if (target.name.includes('[welcome_title]')) {
      this.syncWelcomeTitle(event)
    } else if (target.name.includes('[welcome_tagline]')) {
      this.syncWelcomeTagline(event)
    } else if (target.name.includes('[footer_text]') || target.name.includes('[custom_branding]')) {
      this.syncCustomFooterText(event)
    }
  }

  syncCustomFooterText(event) {
    let text = ""
    const toggle = document.querySelector('input[name="web_widget_channel[custom_branding]"][type="checkbox"]')
    const isCustom = toggle && toggle.checked

    if (isCustom) {
      const input = document.querySelector('input[name*="[footer_text]"]')
      if (input) text = input.value
    }
    
    this.sendMessageToIframe('updateCustomFooterText', { text: text, isCustom: isCustom })
  }

  sendMessageToIframe(action, payload) {
    if (!this.hasIframeTarget) return
    
    // Send message to the iframe safely
    if (this.iframeTarget.contentWindow) {
      this.iframeTarget.contentWindow.postMessage({
        type: 'deskbolic:preview:update',
        action: action,
        payload: payload
      }, '*')
    }
  }

  syncThemeColor(event) {
    let color = "#0f172a"
    if (event && event.target) {
      color = event.target.value || "#0f172a"
    } else {
      const colorInput = document.querySelector('input[name="web_widget_channel[ui_configurations][theme_color]"]')
      if (colorInput) color = colorInput.value || "#0f172a"
    }
    
    // Update the launcher icon color natively
    if (this.hasLauncherTarget) {
      this.launcherTarget.style.backgroundColor = color
    }
    
    // Send to iframe
    this.sendMessageToIframe('updateTheme', { color: color })
  }

  syncPosition(event) {
    let position = "right"
    if (event && event.target) {
      position = event.target.value || "right"
    } else {
      const positionSelect = document.querySelector('select[name="web_widget_channel[ui_configurations][position]"]')
      if (positionSelect) position = positionSelect.value || "right"
    }
    
    // Update the launcher icon position natively
    if (this.hasLauncherTarget) {
      if (position === "left") {
        this.launcherTarget.style.right = "auto"
        this.launcherTarget.style.left = "20px"
      } else {
        this.launcherTarget.style.left = "auto"
        this.launcherTarget.style.right = "20px"
      }
    }
  }

  syncWelcomeTitle(event) {
    let text = "Hi there 👋"
    if (event && event.target) {
      text = event.target.value || text
    } else {
      const titleInput = document.querySelector('input[name*="[welcome_title]"]')
      if (titleInput) text = titleInput.value || text
    }
    
    this.sendMessageToIframe('updateWelcomeTitle', { text: text })
  }

  syncWelcomeTagline(event) {
    let text = "We are here to help you."
    if (event && event.target) {
      text = event.target.value || text
    } else {
      const taglineInput = document.querySelector('input[name*="[welcome_tagline]"]')
      if (taglineInput) text = taglineInput.value || text
    }
    
    this.sendMessageToIframe('updateWelcomeTagline', { text: text })
  }
}
