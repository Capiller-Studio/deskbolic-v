import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container", "localeSelect", "tabTemplate", "panelTemplate", "tabContainer", "panelContainer"]

  addTranslation(event) {
    event.preventDefault()
    
    if (!this.hasLocaleSelectTarget) return
    const select = this.localeSelectTarget
    const locale = select.value
    if (!locale) return
    
    const uniqueId = new Date().getTime()

    if (this.hasTabTemplateTarget && this.hasPanelTemplateTarget) {
      this.addTabbedTranslation(select, locale, uniqueId)
      return
    }
    
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
    const languageLabel = card.querySelector(".translation-language-name, .f-semi-14")
    
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

    if (this.hasTabContainerTarget) {
      const tab = Array.from(this.tabContainerTarget.querySelectorAll('[data-locale]')).find(item => item.dataset.locale === localeInput?.value)
      if (tab) tab.remove()
      const nextTab = this.tabContainerTarget.querySelector('[data-locale]')
      if (nextTab) nextTab.click()
    }

  }

  addTabbedTranslation(select, locale, uniqueId) {
    const option = select.options[select.selectedIndex]
    const languageName = option.text
    const replacements = {
      NEW_RECORD: uniqueId,
      NEW_LOCALE: locale,
      NEW_LANGUAGE: languageName,
      NEW_CODE: locale.slice(0, 2).toUpperCase()
    }
    const replaceTokens = (content) => Object.entries(replacements).reduce(
      (result, [token, value]) => result.replace(new RegExp(token, "g"), value),
      content
    )

    const tabWrapper = document.createElement("div")
    tabWrapper.innerHTML = replaceTokens(this.tabTemplateTarget.innerHTML)
    const panelWrapper = document.createElement("div")
    panelWrapper.innerHTML = replaceTokens(this.panelTemplateTarget.innerHTML)
    const newTab = tabWrapper.firstElementChild
    const newPanel = panelWrapper.firstElementChild
    const localeInput = newPanel.querySelector("input[name*='[locale]']")
    if (localeInput) localeInput.value = locale
    newPanel.dataset.locale = locale
    const panelLanguageName = newPanel.querySelector(".translation-language-name")
    if (panelLanguageName) panelLanguageName.textContent = languageName

    this.tabContainerTarget.insertBefore(newTab, this.tabContainerTarget.querySelector(".ai-agent-language-picker"))
    this.panelContainerTarget.appendChild(newPanel)
    option.remove()
    select.value = ""
    newTab.click()
  }
}
