import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "pool", "modal", "searchInput", "addButtonRow"]

  connect() {
    this.toggleAddButton()
  }

  openModal() {
    this.modalTarget.style.display = "flex"
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
      this.filterFields()
      setTimeout(() => this.searchInputTarget.focus(), 100)
    }
  }

  closeModal() {
    this.modalTarget.style.display = "none"
  }

  filterFields() {
    const query = this.searchInputTarget.value.toLowerCase().trim()
    const items = this.poolTarget.querySelectorAll(".cf-sortable-item")
    
    items.forEach(item => {
      const searchable = item.dataset.searchable || ""
      if (searchable.includes(query)) {
        item.style.display = "flex" // or block depending on layout, we'll use empty to reset
        item.classList.remove('hidden-by-search')
      } else {
        item.style.display = "none"
        item.classList.add('hidden-by-search')
      }
    })
  }

  addFieldFromModal(event) {
    const item = event.currentTarget.closest(".cf-sortable-item")
    if (!item) return

    // Only proceed if the item is currently in the modal pool (prevents issues if clicked while in the active list)
    if (!this.poolTarget.contains(item)) return

    // Move the DOM node into the active sortable list
    this.listTarget.appendChild(item)

    // Enable the hidden input so its value gets submitted with the form
    const hiddenInput = item.querySelector("input[type='hidden'][data-custom-field-builder-target='hiddenInput']")
    if (hiddenInput) hiddenInput.disabled = false

    // Reset search visibility
    item.style.display = ""
    item.classList.remove('hidden-by-search')

    this.toggleAddButton()

    // We do NOT close the modal here to allow adding multiple fields!
  }

  removeField(event) {
    // Prevent event from bubbling up to addFieldFromModal if it's inside the same element somehow
    event.stopPropagation()
    
    const button = event.currentTarget
    const item = button.closest(".sortable-item")
    if (!item) return
    
    // Disable the hidden input so it doesn't get submitted
    const hiddenInput = item.querySelector("input[type='hidden'][data-custom-field-builder-target='hiddenInput']")
    if (hiddenInput) hiddenInput.disabled = true

    // Move the DOM node back to the hidden pool
    this.poolTarget.appendChild(item)

    // Ensure it's visible or respects current search
    if (this.hasSearchInputTarget && this.modalTarget.style.display === "block") {
      this.filterFields()
    } else {
      item.style.display = ""
    }

    this.toggleAddButton()
  }

  toggleAddButton() {
    if (!this.hasAddButtonRowTarget) return
    
    // If pool has no items, hide the add field button
    const hasItems = this.poolTarget.querySelectorAll(".cf-sortable-item").length > 0
    this.addButtonRowTarget.style.display = hasItems ? "flex" : "none"
    
    // Also if we are in the modal and there are no items left, close it
    if (!hasItems && this.hasModalTarget && this.modalTarget.style.display === "block") {
      this.closeModal()
    }
  }
}
