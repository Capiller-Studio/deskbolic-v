import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="section"
export default class extends Controller {
  static targets = ["link"];
  
  toggleSection(event) {
    const targetUrl = event.currentTarget.dataset.url;

    history.pushState(null, '', targetUrl);    
    
    fetch(targetUrl, {
      method: 'GET',
      headers: {
        Accept: 'text/vnd.turbo-stream.html'
      },
    }).then((response) => response.text()).
    then((html) => {
      Turbo.renderStreamMessage(html);
    })
  }
}