import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  connect() {
    this.checkFieldType()
    
    // Listen for global select changes
    const select = document.getElementById('custom_field_field_type_select')
    if (select) {
      select.addEventListener('change', () => this.checkFieldType())
    }
  }

  checkFieldType() {
    const select = document.getElementById('custom_field_field_type_select')
    if (!select) return

    const isSelect = select.value === 'select' || select.value === 'multi_select'
    this.element.classList.toggle("cf-hidden", !isSelect)
  }

  addOption(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)
  }

  removeOption(event) {
    event.preventDefault()
    event.currentTarget.closest('.option-row')?.remove()
  }
}
