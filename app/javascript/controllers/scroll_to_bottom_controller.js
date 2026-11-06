import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const anchor = window.location.hash?.replace("#", "")
    if (anchor && document.getElementById(anchor)) {
      this.scrollToMessage(anchor)
    } else {
      this.scrollToBottom()
    }
    // Watch for new messages being appended
    this.observer = new MutationObserver((mutations) => {
      // Check if nodes were ADDED at the END
      let shouldScroll = false;
      for (let mutation of mutations) {
        if (mutation.addedNodes.length > 0) {
          // If we prepend for pagination, we don't want to scroll to bottom.
          // Prepending usually adds a turbo-frame or elements at the start.
          // Appending adds elements at the end.
          const lastAddedNode = mutation.addedNodes[mutation.addedNodes.length - 1]
          if (lastAddedNode === this.element.lastElementChild || mutation.target.id === 'message-frame') {
            shouldScroll = true;
          }
        }
      }
      if (shouldScroll) {
        this.scrollToBottom()
      }
    })
    
    this.observer.observe(this.element, { childList: true, subtree: true })
  }
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.element.scrollTop = this.element.scrollHeight
    })
  }

  scrollToMessage(anchorId) {
    requestAnimationFrame(() => {
      const el = document.getElementById(anchorId)
      if (el) {
        el.scrollIntoView({ behavior: "smooth", block: "center" })
        // Brief highlight effect
        el.style.transition = "background 0.3s ease"
        el.style.background = "rgba(59, 130, 246, 0.08)"
        setTimeout(() => {
          el.style.background = ""
        }, 2500)
      }
    })
  }
}
