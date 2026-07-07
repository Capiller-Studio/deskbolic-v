import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container", "localeSelect"]

  addTranslation(event) {
    event.preventDefault()
    
    if (!this.hasLocaleSelectTarget) return
    const select = this.localeSelectTarget
    const locale = select.value
    if (!locale) return
    
    const uniqueId = new Date().getTime()
    
    let content = this.templateTarget.innerHTML
    content = content.replace(/NEW_RECORD/g, uniqueId)
    
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = content
    
    // Set locale
    const localeInput = tempDiv.querySelector("input[name*='[locale]']")
    if (localeInput) {
      localeInput.value = locale
    }
    
    // Set the language name in the header
    const languageLabel = tempDiv.querySelector(".f-semi-14")
    if (languageLabel) {
      const option = select.options[select.selectedIndex]
      languageLabel.textContent = option.text
    }
    
    // Append the new child
    this.containerTarget.appendChild(tempDiv.firstElementChild)
    
    // Remove the selected option from the dropdown so they don't add it twice
    select.options[select.selectedIndex].remove()
    select.value = ""
  }

  removeTranslation(event) {
    event.preventDefault()
    const card = event.target.closest('.ww-translation-card')
    
    // Put the option back in the dropdown if it was just added and not saved yet
    const localeInput = card.querySelector("input[name*='[locale]']")
    const languageLabel = card.querySelector(".f-semi-14")
    
    if (localeInput && localeInput.value && languageLabel && this.hasLocaleSelectTarget) {
      // Find if it's an existing record (has an ID)
      const idInput = card.querySelector("input[name*='[id]']")
      
      // If it's a new unsaved record, or we just want to allow re-adding
      const option = document.createElement("option")
      option.value = localeInput.value
      option.text = languageLabel.textContent
      this.localeSelectTarget.add(option)
    }

    const destroyFlag = card.querySelector('.destroy-flag')
    if (destroyFlag) {
      destroyFlag.value = "1"
      card.style.display = 'none'
    } else {
      card.remove()
    }
  }
}
