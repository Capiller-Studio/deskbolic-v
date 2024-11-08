import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["panel", "menu"];
  
  initialize() {
    document.addEventListener("click", this.closeMenuOutside.bind(this));
  }
  
  toggle(event) {
    const target = event.currentTarget;
    const panel = target.nextElementSibling;
    
    if (panel.classList.contains('visible')) {
      panel.classList.toggle('visible');
      panel.previousElementSibling.classList.remove("active-accordian");
    } else {
      panel.classList.toggle('visible'); 
      panel.previousElementSibling.classList.add("active-accordian");
    }
  }
  
  toggle_menu() {
    this.menuTarget.classList.toggle('visible');
  }
  
  closeMenuOutside(event) {
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.menuTarget.classList.remove("visible");
    }
  }
}