import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()

    if (typeof this.dialogTarget.showModal === "function") {
      this.dialogTarget.showModal()
    } else {
      this.dialogTarget.style.display = "flex"
    }
  }

  close(event) {
    if (event) event.preventDefault()

    if (typeof this.dialogTarget.close === "function" && this.dialogTarget.open) {
      this.dialogTarget.close()
    } else {
      this.dialogTarget.style.display = "none"
    }
  }

  closeOnOutsideClick(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
