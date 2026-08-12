import { Controller } from "@hotwired/stimulus"

/**
 * Stimulus controller for the Assignment Policy form.
 *
 * Handles:
 *   - Strategy card selection (show/hide strategy-specific fields)
 *   - Business hours toggle (show/hide business hour group selector)
 *   - Idle reassignment toggle (show/hide idle timeout input)
 */
export default class extends Controller {
  static targets = [
    "strategyGrid",
    "strategyRadio",
    "capacitySection",
    "businessHoursToggle",
    "businessHoursField",
    "businessHoursSelect",
    "idleToggle",
    "idleTimeoutField",
    "skillsToggle",
    "conditionsField",
    "descriptionInput",
    "descriptionCounter"
  ]

  connect() {
    this.updateStrategyUI()
    this.updateDescriptionCounter()
    this.toggleBusinessHours()
  }

  // ── Strategy Selection ──

  selectStrategy(event) {
    const card = event.currentTarget

    // Remove selected class from all cards
    this.element.querySelectorAll(".ap-strategy-card").forEach(c => {
      c.classList.remove("selected")
    })

    // Add selected class to clicked card
    card.classList.add("selected")

    // Check the radio button inside the card
    const radio = card.querySelector("input[type='radio']")
    if (radio) {
      radio.checked = true
    }

    this.updateStrategyUI()
  }

  updateStrategyUI() {
    const selectedRadio = this.strategyRadioTargets.find(r => r.checked)
    if (!selectedRadio) return

    const strategy = selectedRadio.value

    this.element.querySelectorAll(".ap-strategy-card").forEach(card => {
      const radio = card.querySelector("input[type='radio']")
      card.classList.toggle("selected", radio?.checked)
    })

    // Show/hide capacity section (not relevant for manual)
    if (this.hasCapacitySectionTarget) {
      this.capacitySectionTarget.style.display = strategy === "manual" ? "none" : ""
    }
  }

  updateDescriptionCounter() {
    if (!this.hasDescriptionInputTarget || !this.hasDescriptionCounterTarget) return

    const maxLength = this.descriptionInputTarget.getAttribute("maxlength") || 500
    const currentLength = this.descriptionInputTarget.value.length
    this.descriptionCounterTarget.textContent = `${currentLength} / ${maxLength}`
  }

  // ── Business Hours Toggle ──

  toggleBusinessHours() {
    if (this.hasBusinessHoursFieldTarget && this.hasBusinessHoursToggleTarget) {
      const isChecked = this.businessHoursToggleTarget.checked
      this.businessHoursFieldTarget.style.display = isChecked ? "" : "none"

      if (this.hasBusinessHoursSelectTarget) {
        this.businessHoursSelectTarget.required = isChecked
        this.updateBusinessHoursValidation()
      }
    }
  }

  updateBusinessHoursValidation() {
    if (!this.hasBusinessHoursToggleTarget || !this.hasBusinessHoursSelectTarget) return

    const isChecked = this.businessHoursToggleTarget.checked
    this.businessHoursSelectTarget.setAttribute("aria-invalid", (isChecked && !this.businessHoursSelectTarget.validity.valid).toString())
  }

  // ── Idle Timeout Toggle ──

  toggleIdleTimeout() {
    if (this.hasIdleTimeoutFieldTarget && this.hasIdleToggleTarget) {
      const isChecked = this.idleToggleTarget.checked
      this.idleTimeoutFieldTarget.style.display = isChecked ? "" : "none"
    }
  }
}
