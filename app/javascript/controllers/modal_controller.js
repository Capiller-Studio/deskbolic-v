import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()
    this.dialogTarget.style.display = "flex"
  }

  close(event) {
    if (event) event.preventDefault()
    this.dialogTarget.style.display = "none"
  }

  closeOnOutsideClick(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
