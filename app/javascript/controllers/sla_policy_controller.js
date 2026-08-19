import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["businessHoursToggle", "businessHoursField", "descriptionInput", "descriptionCounter"]

  connect() {
    this.updateDescriptionCounter()
  }

  toggleBusinessHours() {
    if (this.hasBusinessHoursToggleTarget && this.hasBusinessHoursFieldTarget) {
      if (this.businessHoursToggleTarget.checked) {
        this.businessHoursFieldTarget.style.display = "block"
      } else {
        this.businessHoursFieldTarget.style.display = "none"
      }
    }
  }

  updateDescriptionCounter() {
    if (!this.hasDescriptionInputTarget || !this.hasDescriptionCounterTarget) return

    this.descriptionCounterTarget.textContent = `${this.descriptionInputTarget.value.length} / 500`
  }
}
