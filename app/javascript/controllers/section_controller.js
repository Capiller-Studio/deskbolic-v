import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="section"
export default class extends Controller {
  static targets = ["link"];
  
  toggleSection(event) {
    event.preventDefault()
    const targetUrl = event.currentTarget.dataset.url;

    const conversationItem = event.currentTarget.closest(".conversation-list-item")
    if (conversationItem) {
      document.querySelectorAll(".conversation-list-item.is-active").forEach((item) => item.classList.remove("is-active"))
      conversationItem.classList.add("is-active")
    }

    const sidebarLink = event.currentTarget.closest(".sidebar-link")
    if (sidebarLink) {
      document.querySelectorAll(".sidebar-link.is-active").forEach((item) => item.classList.remove("is-active"))
      sidebarLink.classList.add("is-active")
    }

    history.pushState(null, '', targetUrl);    
    
    fetch(targetUrl, {
      method: 'GET',
      headers: {
        Accept: 'text/vnd.turbo-stream.html'
      },
    }).then((response) => {
      if (!response.ok) throw new Error(`Request failed with ${response.status}`)
      return response.text()
    }).
    then((html) => {
      Turbo.renderStreamMessage(html);
    }).catch(() => Turbo.visit(targetUrl))
  }
}
