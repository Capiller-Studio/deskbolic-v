import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modalToggler"
export default class extends Controller {
  static targets = ["model"];

  showModal() {
    const model = document.querySelector(".model");
    model.style.display = "block"

    document.addEventListener('click', e => {
      if(model.firstChild === e.target) {
        this.hideModal();
      }
    })
  }
  
  loadModal() {
    this.modelTarget.style.display = "block"

    document.addEventListener('click', e => {
      if(model.firstChild === e.target) {
        this.hideModal();
      }
    })
  }

  hideModal() {
    this.modelTarget.style.display = "none"
  }
}
