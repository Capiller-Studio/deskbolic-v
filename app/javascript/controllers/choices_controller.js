import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="choices"
export default class extends Controller {
  static targets = ["menu", "selected"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    this.menuTarget.classList.toggle("flex")
  }

  select(event) {
    this.selectedTarget.textContent = event.target.value
    this.menuTarget.classList.add("hidden")
    this.menuTarget.classList.remove("flex")
  }
}