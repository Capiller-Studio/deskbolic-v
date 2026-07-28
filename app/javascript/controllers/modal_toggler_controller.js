import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modalToggler"
export default class extends Controller {
  static targets = ["model"];

  get modelContainer() {
    if (this.hasModelTarget) return this.modelTarget;
    return this.element.matches(".model") ? this.element : this.element.querySelector(".model");
  }

  showModal() {
    this.modelContainer.style.display = "block"
    document.querySelectorAll(".menu[data-accordion-target='menu']").forEach(menu => {
      menu.style.display = "none";
    });

    document.addEventListener('click', e => {
      if(this.modelContainer.firstChild === e.target) {
        this.hideModal();
      }
    })
  }
  
  loadModal() {
    this.modelContainer.style.display = "block"

    document.addEventListener('click', e => {
      if(this.modelContainer.firstChild === e.target) {
        this.hideModal();
      }
    })
  }

  hideModal() {
    this.modelContainer.style.display = "none"
    document.querySelectorAll(".menu[data-accordion-target='menu']").forEach(menu => {
      menu.style.display = "";
    });
  }

  closeOnOutsideClick(event) {
    const contentBox = this.modelContainer.querySelector(".model-content");
    if (contentBox && !contentBox.contains(event.target)) {
      this.hideModal();
    }
  }
}
