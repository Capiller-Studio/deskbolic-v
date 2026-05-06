import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showLocale(this.tabTargets[0]?.dataset.locale)
  }

  switch(event) {
    event.preventDefault()
    this.showLocale(event.currentTarget.dataset.locale)
  }

  showLocale(locale) {
    if (!locale) return

    this.tabTargets.forEach(tab => {
      tab.classList.toggle("active", tab.dataset.locale === locale)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("cf-hidden", panel.dataset.locale !== locale)
    })
  }
}
