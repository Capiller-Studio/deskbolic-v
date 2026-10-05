import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "menu",
    "searchInput",
    "resultsContainer",
    "preview",
    "previewBadge",
    "previewTitle",
    "previewDescription",
    "previewActionsList",
    "runButton",
    "runButtonText",
    "runButtonSpinner"
  ]

  static values = {
    conversationId: String,
    availableUrl: { type: String, default: "/macros/available" }
  }

  connect() {
    this.searchTimeout = null
    this.selectedMacro = null
    this.macros = []
    this.selectedIndex = -1

    this.boundCloseMenuOutside = this.closeMenuOutside.bind(this)
    this.boundGlobalKeydown = this.handleGlobalKeydown.bind(this)

    document.addEventListener("click", this.boundCloseMenuOutside)
    document.addEventListener("keydown", this.boundGlobalKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseMenuOutside)
    document.removeEventListener("keydown", this.boundGlobalKeydown)
  }

  handleGlobalKeydown(event) {
    // ⌘+Shift+M or Ctrl+Shift+M to toggle macro picker
    if ((event.metaKey || event.ctrlKey) && event.shiftKey && (event.key === "M" || event.key === "m")) {
      event.preventDefault()
      this.toggleMenu()
    }
  }

  handleKeydown(event) {
    if (!this.hasMenuTarget || !this.menuTarget.classList.contains("visible")) return

    if (event.key === "Escape") {
      event.preventDefault()
      this.closeMenu()
      return
    }

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.navigateResults(1)
      return
    }

    if (event.key === "ArrowUp") {
      event.preventDefault()
      this.navigateResults(-1)
      return
    }

    if (event.key === "Enter") {
      event.preventDefault()
      if (this.selectedMacro) {
        this.runMacro()
      }
    }
  }

  toggleMenu() {
    if (!this.hasMenuTarget) return

    const isOpening = !this.menuTarget.classList.contains("visible")
    this.menuTarget.classList.toggle("visible", isOpening)

    if (isOpening) {
      this.fetchMacros("")
      setTimeout(() => {
        if (this.hasSearchInputTarget) {
          this.searchInputTarget.focus()
          this.searchInputTarget.select()
        }
      }, 50)
    } else {
      this.closePreview()
    }
  }

  closeMenu() {
    if (!this.hasMenuTarget) return
    this.menuTarget.classList.remove("visible")
    this.closePreview()
  }

  closePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.remove("visible")
    }
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("is-previewing")
    }
    this.selectedMacro = null
    this.selectedIndex = -1
  }

  closeMenuOutside(event) {
    if (!this.hasMenuTarget || !this.menuTarget.classList.contains("visible")) return

    const insideMenu = this.element.contains(event.target)
    if (!insideMenu) {
      this.closeMenu()
    }
  }

  search(event) {
    const query = event.target.value
    clearTimeout(this.searchTimeout)

    this.searchTimeout = setTimeout(() => {
      this.fetchMacros(query)
    }, 200)
  }

  fetchMacros(query) {
    const conversationId = this.conversationIdValue
    if (!conversationId) return

    const params = new URLSearchParams()
    params.set("conversation_id", conversationId)
    if (query) params.set("q", query)

    fetch(`${this.availableUrlValue}?${params.toString()}`, {
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`)
        return res.json()
      })
      .then((data) => {
        this.macros = data.macros || []
        this.renderResults(this.macros)
      })
      .catch((err) => {
        console.error("Error fetching macros:", err)
        this.renderError()
      })
  }

  renderResults(macros) {
    if (!this.hasResultsContainerTarget) return

    this.resultsContainerTarget.innerHTML = ""

    if (macros.length === 0) {
      this.resultsContainerTarget.innerHTML = `
        <div class="macro-picker-empty">
          <p class="macro-picker-empty__title">No macros found</p>
          <p class="macro-picker-empty__desc">Create a macro in Settings to automate common tasks.</p>
        </div>
      `
      this.closePreview()
      return
    }

    macros.forEach((macro, index) => {
      const item = document.createElement("div")
      item.className = "menu-link macro-picker-item"
      item.dataset.index = index
      item.dataset.action = "click->macros#selectItem"

      const icon = this.actionIcon(macro.actions)
      const badge = this.visibilityBadge(macro.visibility)
      const actionsCount = macro.actions_count === 1 ? "1 action" : `${macro.actions_count} actions`

      item.innerHTML = `
        <div class="macro-picker-item__icon-wrap">
          ${icon}
        </div>
        <div class="headings macro-picker-item__headings">
          <div class="macro-picker-item__title-row">
            <p class="f-semi-14 macro-picker-item__name">${this.escapeHtml(macro.name)}</p>
            ${badge}
          </div>
          <p class="f-reg-10 macro-picker-item__actions-count">${actionsCount}</p>
        </div>
      `

      this.resultsContainerTarget.appendChild(item)
    })

    // Automatically preview the first macro
    this.selectByIndex(0)
  }

  selectItem(event) {
    const item = event.currentTarget
    const index = parseInt(item.dataset.index, 10)
    this.selectByIndex(index)
  }

  selectByIndex(index) {
    if (index < 0 || index >= this.macros.length) return

    this.selectedIndex = index
    this.selectedMacro = this.macros[index]

    // Update active highlight in results list
    const items = this.resultsContainerTarget.querySelectorAll(".macro-picker-item")
    items.forEach((item, i) => {
      item.classList.toggle("macro-picker-item--active", i === index)
    })

    this.renderPreview(this.selectedMacro)
  }

  navigateResults(direction) {
    if (this.macros.length === 0) return

    let newIndex = this.selectedIndex + direction
    if (newIndex < 0) newIndex = this.macros.length - 1
    if (newIndex >= this.macros.length) newIndex = 0

    this.selectByIndex(newIndex)

    // Scroll active item into view
    const items = this.resultsContainerTarget.querySelectorAll(".macro-picker-item")
    if (items[newIndex]) {
      items[newIndex].scrollIntoView({ block: "nearest" })
    }
  }

  renderPreview(macro) {
    if (!macro) {
      this.closePreview()
      return
    }

    if (this.hasPreviewTitleTarget) {
      this.previewTitleTarget.textContent = macro.name
    }

    if (this.hasPreviewDescriptionTarget) {
      this.previewDescriptionTarget.textContent = macro.description || "No description provided."
    }

    if (this.hasPreviewBadgeTarget) {
      this.previewBadgeTarget.innerHTML = this.visibilityBadge(macro.visibility)
    }

    if (this.hasPreviewActionsListTarget) {
      this.previewActionsListTarget.innerHTML = ""
      const actions = macro.actions || []

      actions.forEach((act, idx) => {
        const li = document.createElement("li")
        li.className = "macro-action-step"
        li.innerHTML = `
          <span class="macro-action-step__number">${idx + 1}</span>
          <div class="macro-action-step__content">
            <strong class="macro-action-step__title">${this.humanizeAction(act.action)}</strong>
            <span class="macro-action-step__detail">${this.actionDetailSummary(act)}</span>
          </div>
        `
        this.previewActionsListTarget.appendChild(li)
      })
    }

    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("visible")
    }

    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("is-previewing")
    }
  }

  runMacro() {
    if (!this.selectedMacro) return

    const macroId = this.selectedMacro.id
    const conversationId = this.conversationIdValue
    if (!macroId || !conversationId) return

    this.setRunLoading(true)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/macros/${macroId}/execute`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/vnd.turbo-stream.html, application/json",
        "X-CSRF-Token": csrfToken,
        "X-Requested-With": "XMLHttpRequest"
      },
      body: JSON.stringify({
        conversation_id: conversationId
      })
    })
      .then(async (response) => {
        const contentType = response.headers.get("content-type") || ""

        if (contentType.includes("text/vnd.turbo-stream.html")) {
          const html = await response.text()
          if (window.Turbo) {
            window.Turbo.renderStreamMessage(html)
          }
          return { success: true }
        }

        return response.json()
      })
      .then(() => {
        this.closeMenu()
      })
      .catch((error) => {
        console.error("Error executing macro:", error)
        alert("Failed to execute macro. Please try again.")
      })
      .finally(() => {
        this.setRunLoading(false)
      })
  }

  setRunLoading(loading) {
    if (!this.hasRunButtonTarget) return

    this.runButtonTarget.disabled = loading
    if (this.hasRunButtonTextTarget) {
      this.runButtonTextTarget.style.display = loading ? "none" : ""
    }
    if (this.hasRunButtonSpinnerTarget) {
      this.runButtonSpinnerTarget.style.display = loading ? "" : "none"
    }
  }

  renderError() {
    if (!this.hasResultsContainerTarget) return
    this.resultsContainerTarget.innerHTML = `
      <div class="macro-picker-empty">
        <p class="macro-picker-empty__title" style="color: #ef4444;">Failed to load macros</p>
      </div>
    `
  }

  humanizeAction(actionName) {
    const map = {
      assign_agent: "Assign Agent",
      assign_team: "Assign Team",
      unassign: "Unassign",
      set_status: "Set Status",
      set_priority: "Set Priority",
      add_label: "Add Label",
      remove_label: "Remove Label",
      set_custom_field: "Set Custom Field",
      send_message: "Send Reply",
      send_email_to_customer: "Send Email to Customer",
      send_email_to_team: "Send Email to Team",
      add_note: "Add Internal Note",
      snooze: "Snooze Conversation",
      resolve: "Resolve Conversation",
      mute_conversation: "Mute Notifications",
      trigger_webhook: "Trigger Webhook",
      set_locale: "Set Locale"
    }
    return map[actionName] || (actionName || "").replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())
  }

  actionDetailSummary(act) {
    const p = act.params || {}
    switch (act.action) {
      case "set_status":
        return `to ${(p.status || "").toUpperCase()}`
      case "set_priority":
        return `to ${(p.priority || "").toUpperCase()}`
      case "send_message":
      case "add_note":
        return p.content ? `"${this.truncate(p.content, 45)}"` : ""
      case "snooze":
        return `for ${p.duration_hours || 1} hours`
      case "set_locale":
        return `to ${(p.locale || "").toUpperCase()}`
      default:
        return ""
    }
  }

  actionIcon(actions) {
    const first = Array.isArray(actions) && actions[0] ? actions[0].action : ""
    let bg = "#F1F5F9"
    let color = "#475569"

    if (/message|note|email/.test(first)) {
      bg = "#EFF6FF"
      color = "#3B82F6"
    } else if (/resolve|status/.test(first)) {
      bg = "#ECFDF5"
      color = "#10B981"
    } else if (/priority/.test(first)) {
      bg = "#FFFBEB"
      color = "#F59E0B"
    } else if (/assign|team/.test(first)) {
      bg = "#FAF5FF"
      color = "#8B5CF6"
    }

    return `
      <div style="width: 26px; height: 26px; border-radius: 6px; background: ${bg}; display: flex; align-items: center; justify-content: center; color: ${color}; font-size: 13px; font-weight: 700;">
        ⚡
      </div>
    `
  }

  visibilityBadge(visibility) {
    if (visibility === "personal") {
      return `<span class="macro-badge-pill macro-badge-pill--personal">Personal</span>`
    }
    if (visibility === "team") {
      return `<span class="macro-badge-pill macro-badge-pill--team">Team</span>`
    }
    return `<span class="macro-badge-pill macro-badge-pill--account">Shared</span>`
  }

  truncate(str, length) {
    if (!str) return ""
    return str.length > length ? str.substring(0, length) + "…" : str
  }

  escapeHtml(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
