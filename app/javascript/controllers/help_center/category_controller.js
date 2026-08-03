import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "hiddenInput", "selected", "dropdown", "searchInput", "list"]

  connect() {
    if (this.hasModalTarget) {
      this.modalTarget.style.display = "none"
    }

    this._boundHandleOpen = this._handleOpenEvent.bind(this)
    document.addEventListener("open-category-modal", this._boundHandleOpen)

    if (this.hasListTarget) {
      this.items = this.listTarget.querySelectorAll(".hc-category-picker-item")
    }

    this._boundCloseOnOutside = this._closePickerOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("open-category-modal", this._boundHandleOpen)
    document.removeEventListener("click", this._boundCloseOnOutside)
  }

  open(event) {
    if (event) event.preventDefault()
    this.modalTarget.style.display = "block"
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.style.display = "none"
  }

  closeOnOutsideClick(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  _handleOpenEvent(_event) {
    if (this.hasModalTarget) {
      this.modalTarget.style.display = "block"
    }
  }

  toggle(event) {
    event.preventDefault()
    const isOpen = this.dropdownTarget.style.display !== "none"
    this.dropdownTarget.style.display = isOpen ? "none" : "block"

    if (!isOpen) {
      this._positionDropdown()
      this.searchInputTarget.value = ""
      this.searchInputTarget.focus()
      this._filterItems("")
      document.addEventListener("click", this._boundCloseOnOutside)
    } else {
      document.removeEventListener("click", this._boundCloseOnOutside)
    }
  }

  select(event) {
    event.preventDefault()
    const button = event.currentTarget
    const value = button.dataset.value
    const text = button.textContent.trim()

    this.hiddenInputTarget.value = value
    this.selectedTarget.textContent = text
    this.dropdownTarget.style.display = "none"
    document.removeEventListener("click", this._boundCloseOnOutside)
  }

  search(event) {
    const query = event.target.value.toLowerCase()
    this._filterItems(query)
  }

  openCreateModal(event) {
    event.preventDefault()
    this.dropdownTarget.style.display = "none"
    document.removeEventListener("click", this._boundCloseOnOutside)

    const openEvent = new CustomEvent("open-category-modal", { bubbles: true })
    this.element.dispatchEvent(openEvent)
  }

  addItem({ id, name }) {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.className = "hc-category-picker-item"
    btn.dataset.value = id
    btn.dataset.action = "click->help-center--category#select"
    btn.textContent = name

    const createRow = this.listTarget.querySelector(".hc-category-picker-create")
    if (createRow) {
      this.listTarget.insertBefore(btn, createRow)
    } else {
      this.listTarget.appendChild(btn)
    }

    this.items = this.listTarget.querySelectorAll(".hc-category-picker-item")
    this._selectItem(id, name)
  }

  _selectItem(value, text) {
    this.hiddenInputTarget.value = value
    this.selectedTarget.textContent = text
    this.dropdownTarget.style.display = "none"
    document.removeEventListener("click", this._boundCloseOnOutside)
  }

  _positionDropdown() {
    const trigger = this.element.querySelector(".hc-category-picker-trigger")
    if (!trigger) return

    const rect = trigger.getBoundingClientRect()
    const dropdown = this.dropdownTarget

    dropdown.style.position = "fixed"
    dropdown.style.top = `${rect.bottom + 4}px`
    dropdown.style.left = `${rect.left}px`
    dropdown.style.width = `${Math.max(rect.width, 320)}px`
    dropdown.style.zIndex = "1000"
  }

  _closePickerOnOutsideClick(event) {
    if (this.hasDropdownTarget && !this.element.contains(event.target)) {
      this.dropdownTarget.style.display = "none"
      document.removeEventListener("click", this._boundCloseOnOutside)
    }
  }

  _filterItems(query) {
    if (!this.items) return
    this.items.forEach(item => {
      const text = item.textContent.toLowerCase()
      item.style.display = text.includes(query) ? "" : "none"
    })
  }

  async submit(event) {
    event.preventDefault()

    const form = event.target
    const formData = new FormData(form)

    try {
      const response = await fetch(form.action, {
        method: form.method,
        body: formData,
        headers: { "Accept": "application/json" },
        credentials: "same-origin"
      })

      if (response.ok) {
        const data = await response.json()

        const pickerEl = document.querySelector('[data-controller="help-center--category"]')
        if (pickerEl && window.Stimulus) {
          const picker = window.Stimulus.getControllerForElementAndIdentifier(pickerEl, "help-center--category")
          if (picker && typeof picker.addItem === "function") {
            picker.addItem({ id: data.id, name: data.name })
          }
        }

        document.querySelectorAll('[data-help-center--category-target="modal"]').forEach(m => {
          m.style.display = "none"
        })

        form.reset()
      } else {
        const err = await response.json()
        alert(err.error || "Failed to create category")
      }
    } catch (error) {
      alert("An error occurred: " + error.message)
    }
  }
}