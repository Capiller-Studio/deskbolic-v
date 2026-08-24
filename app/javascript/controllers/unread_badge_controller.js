import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count"]

  static values = {
    id: String,
    type: String,
    hideZero: { type: Boolean, default: true }
  }

  update(event) {
    const counts = event.detail
    let newCount = 0

    if (this.typeValue === "all") {
      if (counts.inboxes) {
        // Query DOM to find all inbox badges to sum only active/rendered inboxes
        document.querySelectorAll('[data-unread-badge-type-value="inbox"]').forEach(el => {
          const inboxId = el.dataset.unreadBadgeIdValue;
          if (counts.inboxes[inboxId]) {
            newCount += parseInt(counts.inboxes[inboxId]);
          }
        });
      }
    } else if (this.typeValue === "inbox") {
      if (counts.inboxes && counts.inboxes[this.idValue]) {
        newCount = parseInt(counts.inboxes[this.idValue])
      }
    } else if (this.typeValue === "conversation") {
      if (counts.conversations && counts.conversations[this.idValue]) {
        newCount = parseInt(counts.conversations[this.idValue])
      }
    }

    if (this.hasCountTarget) this.countTarget.textContent = newCount

    const shouldShow = newCount > 0 || !this.hideZeroValue
    this.element.style.display = shouldShow ? "" : "none"
  }
}
