import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    this.hasBeenViewed = false
    
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.hasBeenViewed) {
          this.hasBeenViewed = true
          this.startFadeOut()
        }
      })
    }, {
      root: null,
      threshold: 0.1
    })

    this.observer.observe(this.element)
  }

  startFadeOut() {
    setTimeout(() => {
      this.element.style.transition = "opacity 1s ease"
      this.element.style.opacity = "0"
      setTimeout(() => {
        this.element.style.display = "none"
        this.element.remove()
      }, 1000)
    }, this.delayValue)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}
