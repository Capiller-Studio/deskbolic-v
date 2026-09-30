import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "hiddenInput", "selected", "dropdown", "searchInput", "list",
    "iconInput", "iconPreview", "iconPreviewImage", "iconIcon", "iconTitle", "iconSubtitle"]

  connect() {
    if (this.hasModalTarget) {
      this.modalTarget.style.display = "none"
      
      const modalTitle = this.modalTarget.querySelector('.hc-category-modal-header-text h3')
      if (modalTitle) this.originalTitle = modalTitle.textContent
      const modalSubtitle = this.modalTarget.querySelector('.hc-category-modal-header-text p')
      if (modalSubtitle) this.originalSubtitle = modalSubtitle.textContent
      const submitBtn = this.modalTarget.querySelector('.hc-category-submit-btn')
      if (submitBtn) this.originalSubmitText = this._submitButtonText(submitBtn)
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
    
    if (this.hasModalTarget) {
      const form = this.modalTarget.querySelector('form.hc-category-form')
      if (form) {
        form.action = form.dataset.categoryPath || form.action
        const methodInput = form.querySelector('input[name="_method"]')
        if (methodInput) methodInput.remove()
        form.reset()
        this._resetIconPreview()
      }
      
      if (this.originalTitle) {
        const modalTitle = this.modalTarget.querySelector('.hc-category-modal-header-text h3')
        if (modalTitle) modalTitle.textContent = this.originalTitle
      }
      if (this.originalSubtitle) {
        const modalSubtitle = this.modalTarget.querySelector('.hc-category-modal-header-text p')
        if (modalSubtitle) modalSubtitle.textContent = this.originalSubtitle
      }
      if (this.originalSubmitText) {
        const submitBtn = this.modalTarget.querySelector('.hc-category-submit-btn')
        if (submitBtn) this._setSubmitButtonText(submitBtn, this.originalSubmitText)
      }
    }
    this.modalTarget.style.display = "block"
  }

  openEdit(event) {
    if (event) event.preventDefault()
    
    const btn = event.currentTarget
    const id = btn.dataset.id
    const path = btn.dataset.path
    const name = btn.dataset.name
    const description = btn.dataset.description
    const parentId = btn.dataset.parentId
    const visibility = btn.dataset.visibility

    if (this.hasModalTarget) {
      const form = this.modalTarget.querySelector('form.hc-category-form')
      if (form) {
        form.action = path || `${form.dataset.categoryPath || "/help-center/categories"}/${id}`
        
        let methodInput = form.querySelector('input[name="_method"]')
        if (!methodInput) {
          methodInput = document.createElement('input')
          methodInput.type = 'hidden'
          methodInput.name = '_method'
          form.appendChild(methodInput)
        }
        methodInput.value = 'patch'
        
        const nameInput = form.querySelector('input[name="category[name]"]')
        if (nameInput) nameInput.value = name || ''
        
        const descInput = form.querySelector('textarea[name="category[description]"]')
        if (descInput) descInput.value = description || ''
        
        const parentSelect = form.querySelector('select[name="category[parent_id]"]')
        if (parentSelect) this._setSelectValue(parentSelect, parentId || '')
        
        const visibilitySelect = form.querySelector('select[name="category[visibility]"]')
        if (visibilitySelect) this._setSelectValue(visibilitySelect, visibility || 'everyone')
      }

      const modalTitle = this.modalTarget.querySelector('.hc-category-modal-header-text h3')
      if (modalTitle) modalTitle.textContent = "Edit Category"
      const modalSubtitle = this.modalTarget.querySelector('.hc-category-modal-header-text p')
      if (modalSubtitle) modalSubtitle.textContent = "Update your category details"
      const submitBtn = this.modalTarget.querySelector('.hc-category-submit-btn')
      if (submitBtn) this._setSubmitButtonText(submitBtn, "Update Category")
    }

    this.modalTarget.style.display = "block"
  }

  previewIcon() {
    const file = this.iconInputTarget.files[0]
    if (!file) return

    const supportedImageTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if (!supportedImageTypes.includes(file.type)) {
      this.iconInputTarget.value = ""
      window.alert("Unsupported icon format. Please upload JPG, PNG, GIF, or WEBP.")
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this._setIconPreview(e.target.result)
    }
    reader.readAsDataURL(file)
  }

  _setIconPreview(src) {
    if (this.hasIconPreviewImageTarget) {
      this.iconPreviewImageTarget.src = src
    }
    if (this.hasIconPreviewTarget) {
      this.iconPreviewTarget.classList.add("hc-file-upload--selected")
    }
    if (this.hasIconIconTarget) {
      this.iconIconTarget.style.display = "none"
    }
    if (this.hasIconTitleTarget) {
      this.iconTitleTarget.textContent = "Icon selected"
    }
    if (this.hasIconSubtitleTarget) {
      this.iconSubtitleTarget.textContent = "Click to change"
    }
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
    const viewportPadding = 12
    const availableWidth = Math.max(window.innerWidth - viewportPadding * 2, rect.width)
    const dropdownWidth = Math.min(rect.width, availableWidth)
    const left = Math.min(Math.max(rect.left, viewportPadding), window.innerWidth - dropdownWidth - viewportPadding)

    dropdown.style.position = "fixed"
    dropdown.style.top = `${rect.bottom + 6}px`
    dropdown.style.left = `${left}px`
    dropdown.style.width = `${dropdownWidth}px`
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
        this._resetIconPreview()
      } else {
        const err = await response.json()
        alert(err.error || "Failed to create category")
      }
    } catch (error) {
      alert("An error occurred: " + error.message)
    }
  }

  _resetIconPreview() {
    if (this.hasIconPreviewTarget) {
      this.iconPreviewTarget.classList.remove("hc-file-upload--selected")
    }
    if (this.hasIconPreviewImageTarget) {
      this.iconPreviewImageTarget.removeAttribute("src")
    }
    if (this.hasIconIconTarget) {
      this.iconIconTarget.style.display = ""
    }
    if (this.hasIconTitleTarget) {
      this.iconTitleTarget.textContent = "Upload icon"
    }
    if (this.hasIconSubtitleTarget) {
      this.iconSubtitleTarget.textContent = "PNG, JPG, or WebP works best."
    }
  }

  _submitButtonText(button) {
    return button.tagName === "INPUT" ? button.value : button.textContent
  }

  _setSubmitButtonText(button, text) {
    if (button.tagName === "INPUT") {
      button.value = text
    } else {
      button.textContent = text
    }
  }

  _setSelectValue(select, value) {
    select.value = value
    select.dispatchEvent(new CustomEvent("select:set-value", {
      bubbles: true,
      detail: { value }
    }))
  }
}
