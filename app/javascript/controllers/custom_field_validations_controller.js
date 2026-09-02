import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textGroup", "numberGroup"]

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

    const type = select.value
    const hasTextValidations = ['text', 'textarea', 'email', 'url', 'phone'].includes(type)
    const hasNumberValidations = type === 'number'

    this.textGroupTargets.forEach(el => el.style.display = hasTextValidations ? 'block' : 'none')
    this.numberGroupTargets.forEach(el => el.style.display = hasNumberValidations ? 'block' : 'none')

    // Hide the whole conditional block when the selected type has no validations
    if (this.element) {
      this.element.style.display = (hasTextValidations || hasNumberValidations) ? '' : 'none'
    }
  }
}
