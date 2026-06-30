import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabContent"]

  switch(event) {
    // Prevent default button behavior
    event.preventDefault()

    const targetTab = event.currentTarget.dataset.targetTab

    // Update button states
    this.element.querySelectorAll(".wa-tab-btn").forEach(btn => {
      if (btn.dataset.targetTab === targetTab) {
        btn.classList.add("active")
      } else {
        btn.classList.remove("active")
      }
    })

    // Update content states
    this.tabContentTargets.forEach(content => {
      if (content.dataset.tabName === targetTab) {
        content.classList.add("active")
      } else {
        content.classList.remove("active")
      }
    })
  }
}
