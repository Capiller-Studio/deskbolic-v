import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="translator"
export default class extends Controller {
  static targets = ["response", "original", "translation"];
  
  toggle() {
    this.responseTarget.classList.toggle('translated');
  }
  
  toggle_translate() {
    // get original response
    const original_text = this.originalTarget.innerHTML
    
    // translate original_text
    
    // assign to translation
    this.translationTarget.innerHTML = original_text
    this.responseTarget.classList.toggle('translated');
  }
}
