import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="frameToggler"
export default class extends Controller {
  connect() {
  }

  loadModal(event) {
    const popup_view = event.currentTarget.dataset.popupView;
    const model = document.querySelector(".model");
    const itemId = event.currentTarget.dataset.itemId;

    model.innerHTML = '';
    const url = itemId ? `/popup/${popup_view}?id=${itemId}` : `/popup/${popup_view}`;

    fetch(url)
      .then(response => response.text())
      .then(content => {
        model.innerHTML = content;
      });
  }
}
