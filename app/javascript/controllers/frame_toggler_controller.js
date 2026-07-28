import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="frameToggler"
export default class extends Controller {
  static targets = ["model"];

  get modelContainer() {
    if (this.hasModelTarget) return this.modelTarget;
    return this.element.matches(".model") ? this.element : this.element.querySelector(".model");
  }

  connect() {
  }

  loadModal(event) {
    const popup_view = event.currentTarget.dataset.popupView;
    const itemId = event.currentTarget.dataset.itemId;

    this.modelContainer.innerHTML = '';
    const url = event.currentTarget.dataset.url || (itemId ? `/popup/${popup_view}?id=${itemId}` : `/popup/${popup_view}`);

    fetch(url)
      .then(response => response.text())
      .then(content => {
        this.modelContainer.innerHTML = content;
      });
  }
}
