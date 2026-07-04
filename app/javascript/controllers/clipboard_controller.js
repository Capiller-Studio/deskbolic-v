import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  
  copy(event) {
    event.preventDefault()
    
    // Get text from target input or dataset
    const textToCopy = this.hasSourceTarget ? this.sourceTarget.value : this.element.dataset.clipboardText
    
    if (!textToCopy) return

    navigator.clipboard.writeText(textToCopy).then(() => {
      const btn = this.hasButtonTarget ? this.buttonTarget : this.element
      const originalText = btn.innerHTML
      
      btn.innerHTML = "Copied!"
      btn.classList.add("ui-copy-btn--copied")
      
      setTimeout(() => {
        btn.innerHTML = originalText
        btn.classList.remove("ui-copy-btn--copied")
      }, 2000)
    })
  }
}
