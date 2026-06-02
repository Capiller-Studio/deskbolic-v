import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["businessHoursToggle", "businessHoursField"]

  toggleBusinessHours() {
    if (this.hasBusinessHoursToggleTarget && this.hasBusinessHoursFieldTarget) {
      if (this.businessHoursToggleTarget.checked) {
        this.businessHoursFieldTarget.style.display = "block"
      } else {
        this.businessHoursFieldTarget.style.display = "none"
      }
    }
  }
}
