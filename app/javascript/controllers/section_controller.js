import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="section"
export default class extends Controller {
  static targets = ["link"];
  
  toggleSection(event) {
    const targetUrl = event.currentTarget.dataset.url;
    const resourceId = event.currentTarget.dataset.resourceId;

    history.pushState(null, '', `${targetUrl}?resource_id=${resourceId}`);    
    
    fetch(`${targetUrl}?resource_id=${resourceId}`, {
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