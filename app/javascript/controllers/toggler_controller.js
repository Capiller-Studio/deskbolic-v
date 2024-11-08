import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggler"
export default class extends Controller {
  static targets = ["conversation", "ticket", "link", "hide"];

  toggle_link(event) {
    const target = event.currentTarget;
    this.linkTargets.forEach(linkTarget => {
      if (linkTarget !== target) {
        linkTarget.classList.remove("active-tab");
      }
    });
    
    this.hideTargets.forEach(hideTarget => {
      hideTarget.style.display = "none";
    });
    
    target.classList.add("active-tab");
    this[event.target.dataset.itemNameParam + "Target"].style.display = "block";
  }
}
