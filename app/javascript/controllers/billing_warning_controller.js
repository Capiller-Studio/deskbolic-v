import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss(event) {
    event.preventDefault()
    
    // Hide the banner immediately
    this.element.style.display = "none"

    // Fire AJAX request to update session
    fetch("/billing/dismiss_warning", {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      }
    }).catch((error) => console.error("Error dismissing billing warning:", error))
  }
}
