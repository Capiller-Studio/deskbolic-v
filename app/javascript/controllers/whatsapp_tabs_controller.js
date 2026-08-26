import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabContent", "methodOption"]

  switch(event) {
    event.preventDefault()
    const targetTab = event.currentTarget.dataset.targetTab
    if (!targetTab) return

    // Update button visual states
    this.methodOptionTargets.forEach(btn => {
      const isTarget = btn.dataset.targetTab === targetTab
      btn.classList.toggle("is-active", isTarget)
      btn.setAttribute("aria-selected", isTarget ? "true" : "false")
      const checkMark = btn.querySelector(".whatsapp-selected-check")
      if (checkMark) {
        checkMark.style.display = isTarget ? "flex" : "none"
      }
    })

    // Update content visibility
    this.tabContentTargets.forEach(content => {
      if (content.dataset.tabName === targetTab) {
        content.style.display = ""
        content.classList.add("is-active")
      } else {
        content.style.display = "none"
        content.classList.remove("is-active")
      }
    })
  }
}
