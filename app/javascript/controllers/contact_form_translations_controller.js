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
    
    const displaySpan = tempDiv.querySelector("span.f-semi-14")
    if (displaySpan) {
      displaySpan.textContent = select.options[select.selectedIndex].text
    }
    
    this.containerTarget.insertAdjacentHTML('beforeend', tempDiv.innerHTML)
    
    select.options[select.selectedIndex].remove()
    select.value = ""
  }

  removeTranslation(event) {
    event.preventDefault()
    
    const wrapper = event.target.closest('.ww-translation-card')
    const localeInput = wrapper.querySelector("input[name*='[locale]']")
    const locale = localeInput ? localeInput.value : null
    
    const destroyInput = wrapper.querySelector("input[name*='[_destroy]']")
    if (destroyInput) {
      destroyInput.value = "1"
      wrapper.style.display = 'none'
    } else {
      wrapper.remove()
    }
    
    if (locale && this.hasLocaleSelectTarget) {
      const select = this.localeSelectTarget
      const option = document.createElement("option")
      option.value = locale
      
      const displaySpan = wrapper.querySelector("span.f-semi-14")
      option.text = displaySpan ? displaySpan.textContent : locale.toUpperCase()
      
      select.add(option)
    }
  }
}
