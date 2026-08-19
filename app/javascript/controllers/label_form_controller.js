import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["colorField", "swatch", "colorDot", "colorValue", "description", "descriptionCount"]

  connect() {
    this.updateColorSelection()
    this.updateDescriptionCount()
  }

  selectColor(event) {
    this.colorFieldTarget.value = event.currentTarget.dataset.color
    this.updateColorSelection()
  }

  updateColorSelection() {
    const selectedColor = this.colorFieldTarget.value.toUpperCase()

    this.swatchTargets.forEach((swatch) => {
      const selected = swatch.dataset.color === selectedColor
      swatch.classList.toggle("is-selected", selected)
      swatch.setAttribute("aria-checked", selected.toString())
    })

    this.colorDotTarget.style.backgroundColor = selectedColor
    this.colorValueTarget.textContent = selectedColor
  }

  updateDescriptionCount() {
    this.descriptionCountTarget.textContent = this.descriptionTarget.value.length
  }
}
