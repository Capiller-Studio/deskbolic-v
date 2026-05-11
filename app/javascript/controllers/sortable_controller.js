import { Controller } from "@hotwired/stimulus"

/**
 * SortableController
 *
 * Lightweight drag-and-drop reordering using native HTML5 Drag and Drop API.
 * Sends the new order to the server via a PATCH request.
 */
export default class extends Controller {
  static targets = ["item", "handle"]
  static values = { url: String }

  connect() {
    this.dragItem = null
  }

  dragStart(event) {
    this.dragItem = event.target.closest("[data-sortable-target='item']")
    if (!this.dragItem) return

    this.dragItem.classList.add("dragging")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragItem.dataset.id)

    // Add drag-over listeners to all items
    this.itemTargets.forEach(item => {
      item.addEventListener("dragover", this._handleDragOver)
      item.addEventListener("dragleave", this._handleDragLeave)
      item.addEventListener("drop", this._handleDrop)
    })
  }

  dragEnd(_event) {
    if (this.dragItem) {
      this.dragItem.classList.remove("dragging")
    }

    // Remove all drag-over states and listeners
    this.itemTargets.forEach(item => {
      item.classList.remove("drag-over")
      item.removeEventListener("dragover", this._handleDragOver)
      item.removeEventListener("dragleave", this._handleDragLeave)
      item.removeEventListener("drop", this._handleDrop)
    })

    this.dragItem = null
  }

  _handleDragOver = (event) => {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    const target = event.target.closest("[data-sortable-target='item']")
    if (target && target !== this.dragItem) {
      target.classList.add("drag-over")
    }
  }

  _handleDragLeave = (event) => {
    const target = event.target.closest("[data-sortable-target='item']")
    if (target) target.classList.remove("drag-over")
  }

  _handleDrop = (event) => {
    event.preventDefault()
    const target = event.target.closest("[data-sortable-target='item']")
    if (!target || target === this.dragItem) return

    target.classList.remove("drag-over")

    // Reorder DOM
    const container = this.dragItem.parentNode
    const items = Array.from(container.children)
    const dragIndex = items.indexOf(this.dragItem)
    const dropIndex = items.indexOf(target)

    if (dragIndex < dropIndex) {
      target.after(this.dragItem)
    } else {
      target.before(this.dragItem)
    }

    // Send new order to server
    this._saveOrder()
  }

  _saveOrder() {
    const orderedIds = this.itemTargets.map(item => item.dataset.id)

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({ ordered_ids: orderedIds })
    })
  }
}
