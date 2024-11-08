import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="frameToggler"
export default class extends Controller {
  connect() {
  }

  loadModal(event) {
    const popup_view = event.currentTarget.dataset.popupView;
    const model = document.querySelector(".model");

    model.innerHTML = '';
    fetch(`/popup/${popup_view}`)
      .then(response => response.text())
      .then(content => {
        model.innerHTML = content;
      });
  }
}
