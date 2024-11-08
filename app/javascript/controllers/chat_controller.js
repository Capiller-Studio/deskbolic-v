import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ["link"];
  
  connect() {
    let divElement = document.getElementById('oppp');
    
    if (divElement) {
      divElement.scrollTop = divElement.scrollHeight;
    }
  }
}