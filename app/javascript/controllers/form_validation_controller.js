import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];

  validate(event) {
    console.log("im here for validation");
    if (this.formTarget.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
    }
    this.formTarget.classList.add("was-validated");
  }
}