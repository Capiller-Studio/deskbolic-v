import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="translator"
export default class extends Controller {
  static targets = ["response", "original", "translation"];
  static values = { translateUrl: String }
  
  toggle() {
    this.responseTarget.classList.toggle('translated');
  }
  
  async toggle_translate() {
    if (this.translationTarget.innerHTML.trim() !== "") {
      this.responseTarget.classList.toggle('translated');
      return;
    }
    
    // show loading state
    this.translationTarget.innerHTML = "Translating...";
    this.responseTarget.classList.toggle('translated');
    
    try {
      const response = await fetch(this.translateUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      });
      const data = await response.json();
      if (data.success) {
        this.translationTarget.innerHTML = data.text;
      } else {
        this.translationTarget.innerHTML = "Translation failed.";
      }
    } catch (e) {
      this.translationTarget.innerHTML = "Translation error.";
    }
  }
}
