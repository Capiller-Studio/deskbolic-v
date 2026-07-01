import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: String,
    type: String
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

    if (newCount > 0) {
      this.element.style.display = "flex"
      this.element.querySelector("p").textContent = newCount
    } else {
      this.element.style.display = "none"
      this.element.querySelector("p").textContent = "0"
    }
  }
}
