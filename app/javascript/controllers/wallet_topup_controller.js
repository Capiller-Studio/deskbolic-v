import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  setAmount(event) {
    event.preventDefault()
    const amount = event.currentTarget.dataset.amount
    this.inputTarget.value = amount
  }
}
