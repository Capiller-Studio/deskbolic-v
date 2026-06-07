import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container", "localeSelect"]

  addTranslation(event) {
    event.preventDefault()
    
    if (!this.hasLocaleSelectTarget) return
    const select = this.localeSelectTarget
    const locale = select.value
    if (!locale) return
    
    // Generate a unique ID for the new fields
    const uniqueId = new Date().getTime()
    
    // Get the template content and replace NEW_RECORD
    let content = this.templateTarget.innerHTML
    content = content.replace(/NEW_RECORD/g, uniqueId)
    
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = content
    
    // Find the locale input and set its value to the selected locale
    const localeInput = tempDiv.querySelector(".ww-locale-hidden")
    if (localeInput) {
      localeInput.setAttribute('value', locale)
    }

    // Set the human readable name and remove NEW_LOCALE_LABEL
    const displayInput = tempDiv.querySelector(".ww-locale-display")
    if (displayInput) {
      displayInput.setAttribute('value', select.options[select.selectedIndex].text)
    }
    
    // Append the new translation block
    this.containerTarget.insertAdjacentHTML('beforeend', tempDiv.innerHTML)
    
    // Remove the selected option from the dropdown
    select.options[select.selectedIndex].remove()
    select.value = ""
  }

  removeTranslation(event) {
    event.preventDefault()
    
    const wrapper = event.target.closest('.ww-translation-block')
    const localeInput = wrapper.querySelector("input[name*='[locale]']")
    const locale = localeInput ? localeInput.value : null
    
    // If it's an existing record, we mark the hidden _destroy field as 1
    const destroyInput = wrapper.querySelector("input[name*='[_destroy]']")
    if (destroyInput) {
      destroyInput.value = "1"
      wrapper.style.display = 'none'
    } else {
      // If it's a new record that hasn't been saved, just remove it from DOM
      wrapper.remove()
    }
    
    // Add the locale back to the dropdown
    if (locale && this.hasLocaleSelectTarget) {
      const select = this.localeSelectTarget
      const option = document.createElement("option")
      option.value = locale
      
      const displayInput = wrapper.querySelector(".ww-locale-display")
      option.text = displayInput ? displayInput.value : locale.toUpperCase()
      
      select.add(option)
    }
  }
}
