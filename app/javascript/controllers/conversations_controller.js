import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  open() {
    this.modalTarget.classList.add("show");
    this.modalTarget.style.display = "block";
  }

  close() {
    this.modalTarget.classList.remove("show");
    this.modalTarget.style.display = "none";
  }
}