import { Controller } from "@hotwired/stimulus"
import Choices from 'choices.js'

// Connects to data-controller="select"
export default class extends Controller {
  connect() {
    const choices = new Choices(this.element, {
      silent: true,
      searchEnabled: true,
      itemSelectText: 'choose an option',
      allowHTML: true
    });
  }
}