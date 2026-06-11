import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entityType", "mappedTo"]

  connect() {
    this.filterMappings()
  }

  filterMappings() {
    if (!this.hasEntityTypeTarget || !this.hasMappedToTarget) return

    const entityType = this.entityTypeTarget.value
    const options = Array.from(this.mappedToTarget.options)

    options.forEach(option => {
      if (option.value === "") return // Keep the blank option

      let shouldShow = false
      if (entityType === "customer") {
        shouldShow = option.value.startsWith("customer.")
      } else if (entityType === "conversation") {
        shouldShow = option.value.startsWith("conversation.") || option.value.startsWith("message.")
      } else {
        shouldShow = true
      }

      option.hidden = !shouldShow
      option.disabled = !shouldShow
      
      // If the currently selected option is hidden, reset to blank
      if (!shouldShow && option.selected) {
        this.mappedToTarget.value = ""
      }
    })
  }
}
