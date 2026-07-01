import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.markAsRead()

    // Watch for new messages being appended to the chat
    this.observer = new MutationObserver((mutations) => {
      let hasNewMessages = false
      for (let mutation of mutations) {
        if (mutation.addedNodes.length > 0) {
          // If nodes are appended to the end of the conversation (via AnyCable)
          const lastAddedNode = mutation.addedNodes[mutation.addedNodes.length - 1]
          if (lastAddedNode === this.element.lastElementChild || mutation.target.id === 'message-frame') {
            hasNewMessages = true
          }
        }
      }

      // If document is visible and focused, mark as read immediately
      if (hasNewMessages) {
        if (document.visibilityState === 'visible' && document.hasFocus()) {
          this.markAsRead()
        } else {
          // Wait until user comes back to the tab and focuses it
          const focusHandler = () => {
            if (document.visibilityState === 'visible' && document.hasFocus()) {
              this.markAsRead()
              window.removeEventListener("focus", focusHandler)
              document.removeEventListener("visibilitychange", visibilityHandler)
            }
          }
          const visibilityHandler = () => {
            if (document.visibilityState === 'visible' && document.hasFocus()) {
              this.markAsRead()
              window.removeEventListener("focus", focusHandler)
              document.removeEventListener("visibilitychange", visibilityHandler)
            }
          }
          window.addEventListener("focus", focusHandler)
          document.addEventListener("visibilitychange", visibilityHandler)
        }
      }
    })

    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  handleVisibilityChange() {
    if (document.visibilityState === 'visible') {
      this.markAsRead()
    }
  }

  markAsRead() {
    if (!this.urlValue) return

    const csrfToken = document.querySelector("meta[name='csrf-token']").content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      }
    }).catch(error => console.error("Error marking as read:", error))
  }
}
