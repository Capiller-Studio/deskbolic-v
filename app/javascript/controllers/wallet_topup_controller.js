import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "customInput", "preset"]

  selectPreset(event) {
    event.preventDefault()
    this.inputTarget.value = event.params.amount
    if (this.hasCustomInputTarget) this.customInputTarget.value = ""
    this.presetTargets.forEach((preset) => {
      preset.classList.toggle("is-selected", preset === event.currentTarget)
    })
  }

  useCustomAmount() {
    this.inputTarget.value = this.customInputTarget.value
    this.presetTargets.forEach((preset) => preset.classList.remove("is-selected"))
  }
}
