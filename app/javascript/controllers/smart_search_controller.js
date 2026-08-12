import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "input", "results", "quickActionResults", "conversationResults", "messageResults", "empty", "loading"]
  static values = { quickActions: Array, sectionLabels: Object }

  connect() {
    this.debounceTimer = null
    this.selectedIndex = -1
    this.resultItems = []

    // Global keyboard shortcut: Cmd+K / Ctrl+K
    this.handleKeydown = this._handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  _handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "k") {
      event.preventDefault()
      this.toggle()
    }
    if (event.key === "Escape" && this.isOpen()) {
      this.close()
    }
  }

  toggle() {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.modalTarget.classList.add("active")
    document.body.style.overflow = "hidden"
    requestAnimationFrame(() => {
      this.inputTarget.focus()
      this.inputTarget.select()
    })
  }

  close() {
    this.modalTarget.classList.remove("active")
    document.body.style.overflow = ""
    this.inputTarget.value = ""
    this.clearResults()
    this.selectedIndex = -1
  }

  isOpen() {
    return this.modalTarget.classList.contains("active")
  }

  onInput(event) {
    const query = event.target.value.trim()
    clearTimeout(this.debounceTimer)

    if (query.length < 2) {
      this.clearResults()
      return
    }

    // Instant: filter quick actions client-side (no debounce)
    this.filterQuickActions(query)

    // Debounced: fetch conversations/messages from server
    this.showLoading()
    this.debounceTimer = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 250)
  }

  onKeydown(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveSelection(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveSelection(-1)
    } else if (event.key === "Enter") {
      event.preventDefault()
      this.selectCurrent()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  // ---- Quick Actions (client-side) ----

  filterQuickActions(query) {
    const q = query.toLowerCase()
    const matches = this.quickActionsValue.filter(action => {
      const searchable = `${action.label} ${action.keywords} ${action.category}`.toLowerCase()
      return q.split(/\s+/).every(word => searchable.includes(word))
    }).slice(0, 6)

    if (matches.length > 0) {
      // Group by category
      const groups = {}
      matches.forEach(action => {
        if (!groups[action.category]) groups[action.category] = []
        groups[action.category].push(action)
      })

      let html = `
        <div class="smart-search-section-header">
          <span class="smart-search-section-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>
          </span>
          <span>${this.sectionLabelsValue.quick_actions || "Quick Actions"}</span>
        </div>
      `
      let globalIndex = 0
      matches.forEach((action, i) => {
        html += this.renderQuickActionItem(action, globalIndex)
        globalIndex++
      })

      this.quickActionResultsTarget.innerHTML = html
      this.quickActionResultsTarget.style.display = "block"
      this.resultsTarget.classList.add("has-results")
      this.hideEmpty()
    } else {
      this.quickActionResultsTarget.innerHTML = ""
      this.quickActionResultsTarget.style.display = "none"
    }

    this.refreshResultItems()
  }

  renderQuickActionItem(action, index) {
    const isCreate = action.category.includes("Create")
    const icon = isCreate
      ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>'
      : '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>'

    return `
      <a href="${action.url}" class="smart-search-result-item smart-search-quick-action" data-index="${index}" data-action="mouseenter->smart-search#highlightItem">
        <div class="smart-search-result-main">
          <div class="smart-search-result-header">
            <span class="smart-search-quick-action-icon">${icon}</span>
            <span class="smart-search-result-title">${this.escapeHtml(action.label)}</span>
          </div>
        </div>
        <div class="smart-search-result-meta">
          <span class="smart-search-result-category">${this.escapeHtml(action.category)}</span>
        </div>
      </a>
    `
  }

  // ---- Server Search (conversations + messages) ----

  async fetchSuggestions(query) {
    try {
      const response = await fetch(`/search/suggestions?q=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        }
      })

      if (!response.ok) throw new Error("Search request failed")

      const data = await response.json()
      this.renderServerResults(data, query)
    } catch (error) {
      console.error("[SmartSearch]", error)
      this.hideLoading()
      // If no quick actions matched either, show empty
      if (this.quickActionResultsTarget.style.display === "none") {
        this.showEmpty()
      }
    }
  }

  renderServerResults(data, query) {
    const hasConversations = data.conversations && data.conversations.length > 0
    const hasMessages = data.messages && data.messages.length > 0
    const hasQuickActions = this.quickActionResultsTarget.style.display === "block"

    this.hideLoading()

    if (!hasConversations && !hasMessages && !hasQuickActions) {
      this.showEmpty()
      return
    }

    this.hideEmpty()
    this.resultsTarget.classList.add("has-results")

    // Calculate offset from quick actions
    const quickActionCount = this.quickActionResultsTarget.querySelectorAll(".smart-search-result-item").length

    if (hasConversations) {
      this.conversationResultsTarget.innerHTML = `
        <div class="smart-search-section-header">
          <span class="smart-search-section-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
          </span>
          <span>${this.sectionLabelsValue.conversations || "Conversations"}</span>
        </div>
        ${data.conversations.map((conv, i) => this.renderConversationItem(conv, quickActionCount + i)).join("")}
      `
      this.conversationResultsTarget.style.display = "block"
    } else {
      this.conversationResultsTarget.style.display = "none"
      this.conversationResultsTarget.innerHTML = ""
    }

    if (hasMessages) {
      const msgOffset = quickActionCount + (hasConversations ? data.conversations.length : 0)
      this.messageResultsTarget.innerHTML = `
        <div class="smart-search-section-header">
          <span class="smart-search-section-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
          </span>
          <span>${this.sectionLabelsValue.messages || "Messages"}</span>
        </div>
        ${data.messages.map((msg, i) => this.renderMessageItem(msg, msgOffset + i)).join("")}
      `
      this.messageResultsTarget.style.display = "block"
    } else {
      this.messageResultsTarget.style.display = "none"
      this.messageResultsTarget.innerHTML = ""
    }

    this.refreshResultItems()
  }

  renderConversationItem(conv, index) {
    const statusClass = `status-${conv.status}`
    const priorityIcon = this.priorityIcon(conv.priority)
    return `
      <a href="${conv.url}" class="smart-search-result-item" data-index="${index}" data-action="mouseenter->smart-search#highlightItem">
        <div class="smart-search-result-main">
          <div class="smart-search-result-header">
            <span class="smart-search-result-id">${conv.identifier}</span>
            <span class="smart-search-result-badge ${statusClass}">${conv.status}</span>
            ${priorityIcon ? `<span class="smart-search-result-priority">${priorityIcon}</span>` : ""}
          </div>
          <div class="smart-search-result-title">${conv.customer_name || this.sectionLabelsValue.unknown_customer || "Unknown"}</div>
          ${conv.title ? `<div class="smart-search-result-subtitle">${this.escapeHtml(conv.title)}</div>` : ""}
        </div>
        <div class="smart-search-result-meta">
          <span class="smart-search-result-inbox">${conv.inbox_name || ""}</span>
          <span class="smart-search-result-date">${conv.last_activity_at || ""}</span>
        </div>
      </a>
    `
  }

  renderMessageItem(msg, index) {
    const senderIcon = msg.sender_type === "Customer" ? "↙" : "↗"
    return `
      <a href="${msg.url}" class="smart-search-result-item smart-search-result-message" data-index="${index}" data-action="mouseenter->smart-search#highlightItem">
        <div class="smart-search-result-main">
          <div class="smart-search-result-header">
            <span class="smart-search-result-id">${msg.conversation_identifier}</span>
            <span class="smart-search-result-sender">${senderIcon} ${this.escapeHtml(msg.sender_name || this.sectionLabelsValue.unknown_sender || "Unknown")}</span>
          </div>
          <div class="smart-search-result-content">${msg.content}</div>
        </div>
        <div class="smart-search-result-meta">
          <span class="smart-search-result-date">${msg.created_at || ""}</span>
        </div>
      </a>
    `
  }

  priorityIcon(priority) {
    const icons = {
      urgent: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#EF4444" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
      high: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#F97316" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>',
      medium: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#EAB308" stroke-width="2"><line x1="5" y1="12" x2="19" y2="12"/></svg>',
      low: null
    }
    return icons[priority] || null
  }

  // ---- Navigation Helpers ----

  refreshResultItems() {
    this.resultItems = this.resultsTarget.querySelectorAll(".smart-search-result-item")
    this.selectedIndex = -1
  }

  highlightItem(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.updateSelection(index)
  }

  moveSelection(direction) {
    if (this.resultItems.length === 0) return

    let newIndex = this.selectedIndex + direction
    if (newIndex < 0) newIndex = this.resultItems.length - 1
    if (newIndex >= this.resultItems.length) newIndex = 0

    this.updateSelection(newIndex)
  }

  updateSelection(index) {
    this.resultItems.forEach(item => item.classList.remove("selected"))
    this.selectedIndex = index
    if (this.resultItems[index]) {
      this.resultItems[index].classList.add("selected")
      this.resultItems[index].scrollIntoView({ block: "nearest" })
    }
  }

  selectCurrent() {
    if (this.selectedIndex >= 0 && this.resultItems[this.selectedIndex]) {
      this.resultItems[this.selectedIndex].click()
    } else {
      const query = this.inputTarget.value.trim()
      if (query.length > 0) {
        window.location.href = `/search?q=${encodeURIComponent(query)}`
      }
    }
  }

  clearResults() {
    this.resultsTarget.classList.remove("has-results")
    this.quickActionResultsTarget.innerHTML = ""
    this.quickActionResultsTarget.style.display = "none"
    this.conversationResultsTarget.innerHTML = ""
    this.conversationResultsTarget.style.display = "none"
    this.messageResultsTarget.innerHTML = ""
    this.messageResultsTarget.style.display = "none"
    this.hideLoading()
    this.hideEmpty()
    this.resultItems = []
    this.selectedIndex = -1
  }

  showLoading() {
    this.loadingTarget.style.display = "flex"
    this.hideEmpty()
  }

  hideLoading() {
    this.loadingTarget.style.display = "none"
  }

  showEmpty() {
    this.hideLoading()
    this.emptyTarget.style.display = "flex"
    this.quickActionResultsTarget.style.display = "none"
    this.conversationResultsTarget.style.display = "none"
    this.messageResultsTarget.style.display = "none"
    this.resultsTarget.classList.remove("has-results")
  }

  hideEmpty() {
    this.emptyTarget.style.display = "none"
  }

  escapeHtml(text) {
    if (!text) return ""
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
