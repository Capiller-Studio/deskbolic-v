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
    const locale = document.documentElement.lang;
    const localePrefix = locale && locale !== "en" ? `/${encodeURIComponent(locale)}` : "";
    const popupUrl = new URL(`${localePrefix}/popup/${encodeURIComponent(popup_view)}`, window.location.origin);

    if (itemId) popupUrl.searchParams.set("id", itemId);

    const url = event.currentTarget.dataset.url || `${popupUrl.pathname}${popupUrl.search}`;

    fetch(url)
      .then(response => response.text())
      .then(content => {
        this.modelContainer.innerHTML = content;
      });
  }
}
