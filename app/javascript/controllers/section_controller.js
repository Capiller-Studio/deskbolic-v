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
      this.showMobileInbox()
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
      if (conversationItem) this.showMobileConversation()
    }).catch(() => Turbo.visit(targetUrl))
  }

  backToList(event) {
    event.preventDefault()
    const targetUrl = event.currentTarget.dataset.url

    document.querySelector(".conversations-workspace")?.classList.remove("is-conversation-open")
    document.querySelector(".deskbolic-shell")?.classList.remove("is-mobile-conversation-open")

    if (targetUrl) history.pushState(null, "", targetUrl)
  }

  showMobileInbox() {
    document.querySelector(".deskbolic-shell")?.classList.remove("mobile-view-inboxes")

    document.querySelectorAll("[data-mobile-dashboard-tab]").forEach((item) => {
      const active = item.dataset.mobileDashboardTab === "inbox"
      item.classList.toggle("is-active", active)

      if (active) {
        item.setAttribute("aria-current", "page")
      } else {
        item.removeAttribute("aria-current")
      }
    })
  }

  showMobileConversation() {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        document.querySelector(".conversations-workspace")?.classList.add("is-conversation-open")
        document.querySelector(".deskbolic-shell")?.classList.add("is-mobile-conversation-open")
      })
    })
  }
}
