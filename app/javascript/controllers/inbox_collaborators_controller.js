import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "count", "selectAllBtn", "clearBtn", "query", "item", "empty"]

  connect() {
    this.updateCount()
  }

  filter() {
    const query = this.hasQueryTarget ? this.queryTarget.value.trim().toLowerCase() : ""
    let visibleCount = 0

    this.itemTargets.forEach((item) => {
      const text = (item.dataset.searchable || "").toLowerCase()
      const visible = !query || text.includes(query)
      item.style.display = visible ? "" : "none"
      if (visible) visibleCount += 1
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.style.display = visibleCount > 0 ? "none" : ""
    }
  }

  selectAll() {
    this.checkboxTargets.forEach((checkbox) => {
      const item = checkbox.closest("[data-inbox-collaborators-target='item']")
      if (!item || item.style.display !== "none") {
        checkbox.checked = true
      }
    })
    this.updateCount()
  }

  clearAll() {
    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = false
    })
    this.updateCount()
  }

  updateCount() {
    const checkedCount = this.checkboxTargets.filter((cb) => cb.checked).length
    if (this.hasCountTarget) {
      this.countTarget.textContent = checkedCount
    }
  }

  toggleRow(event) {
    if (event.target.tagName === "INPUT" || event.target.tagName === "LABEL" || event.target.closest("label")) return

    const checkbox = event.currentTarget.querySelector("input[type='checkbox']")
    if (checkbox) {
      checkbox.checked = !checkbox.checked
      this.updateCount()
    }
  }

  closeModal() {
    const modalPopper = this.element.closest(".modal-popper-container") ||
                        document.querySelector(".model.modal-popper-container") ||
                        document.querySelector(".modal-popper-container")
    if (modalPopper) {
      modalPopper.style.display = "none"
      modalPopper.innerHTML = ""
      document.querySelectorAll(".menu[data-accordion-target='menu']").forEach((menu) => {
        menu.style.display = ""
      })
    }
  }

  handleSubmitEnd(event) {
    if (event.detail && event.detail.success) {
      this.closeModal()
    }
  }
}
