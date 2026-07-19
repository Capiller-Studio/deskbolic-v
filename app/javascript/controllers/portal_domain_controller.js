import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "radio", "subdomainSection", "customSection", "submitButton"]
  static values = { hasDomains: Boolean }

  connect() {
    this.sync()
  }

  select(event) {
    event.preventDefault()
    
    // Find the radio button inside the clicked label
    const input = event.currentTarget.querySelector('input[type="radio"]')
    if (!input || input.disabled) return

    input.checked = true
    this.sync()
  }

  sync() {
    // Update the .is-selected class on the labels
    this.optionTargets.forEach((option) => {
      const input = option.querySelector('input[type="radio"]')
      option.classList.toggle("is-selected", input && input.checked)
    })

    // Find which value is checked
    let selectedValue = "subdomain"
    this.radioTargets.forEach((radio) => {
      if (radio.checked) selectedValue = radio.value
    })

    // Toggle sections based on selected value
    if (this.hasSubdomainSectionTarget) {
      this.subdomainSectionTarget.style.display = selectedValue === "subdomain" ? "block" : "none"
    }
    
    if (this.hasCustomSectionTarget) {
      this.customSectionTarget.style.display = selectedValue === "custom" ? "block" : "none"
    }

    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = (selectedValue === "custom" && !this.hasDomainsValue)
    }
  }
}
