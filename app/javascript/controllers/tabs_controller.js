import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  switch(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.add("active")
        tab.setAttribute("aria-selected", "true")
      } else {
        tab.classList.remove("active")
        tab.setAttribute("aria-selected", "false")
      }
    })

    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.style.display = "block"
      } else {
        panel.style.display = "none"
      }
    })
  }
}
