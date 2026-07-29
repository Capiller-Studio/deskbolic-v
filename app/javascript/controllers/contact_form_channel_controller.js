import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "appearanceSection", "integrationsSection", "behaviorsSection", "translationsSection",
    "colorSwatch", "colorInput", "customBrandingFields"
  ]

  toggleCustomBranding(event) {
    if (this.hasCustomBrandingFieldsTarget) {
      this.customBrandingFieldsTarget.style.display = event.target.checked ? 'block' : 'none'
    }
  }

  toggleSection(event) {
    const section = event.currentTarget.closest(".ui-section")
    if (section) {
      section.classList.toggle("ui-section--open")
    }
  }

  syncColor(event) {
    const hex = event.target.value
    if (this.hasColorInputTarget) {
      this.colorInputTarget.value = hex
    }
  }

  syncSwatch(event) {
    const hex = event.target.value
    if (/^#[0-9A-F]{6}$/i.test(hex) && this.hasColorSwatchTarget) {
      this.colorSwatchTarget.value = hex
    }
  }

  copyEmbedCode(event) {
    const btn = event.currentTarget
    const code = btn.dataset.code

    navigator.clipboard.writeText(code).then(() => {
      const originalText = btn.innerHTML
      btn.innerHTML = btn.dataset.successText || "✓ Copied!"
      btn.classList.add("ui-copy-btn--copied")

      setTimeout(() => {
        btn.innerHTML = originalText
        btn.classList.remove("ui-copy-btn--copied")
      }, 2000)
    })
  }
}
