import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  selectPreset(event) {
    event.preventDefault()
    this.inputTarget.value = event.params.amount
  }
}
