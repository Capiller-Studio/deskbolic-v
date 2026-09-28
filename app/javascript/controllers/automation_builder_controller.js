import { Controller } from "@hotwired/stimulus"

/**
 * AutomationBuilderController
 *
 * Orchestrates the automation/macro builder form:
 * - Cascading: event → attributes, attribute → operators, attribute → value field
 * - AJAX-powered dropdowns for agents, teams, inboxes, labels
 * - Serializes the visual form into JSONB hidden fields on submit
 */
export default class extends Controller {
  static targets = [
    "eventSelect",
    "conditionsContainer",
    "conditionGroups",
    "actionsContainer",
    "actionRows",
    "conditionsField",
    "actionsField",
    "stopProcessing",
    "descriptionInput",
    "descriptionCounter",
    "topOperatorField"
  ]

  static values = {
    lookupsUrl: { type: String, default: "/automations/lookups" }
  }

  // =========================================================================
  // DATA REGISTRIES
  // =========================================================================

  // Each attribute has a type that determines valid operators and value fields
  get ATTRIBUTE_REGISTRY() {
    return {
      "status":              { label: "Conversation Status", type: "enum" },
      "priority":            { label: "Priority",            type: "enum" },
      "source":              { label: "Source",               type: "enum" },
      "locale":              { label: "Locale",               type: "string" },
      "title":               { label: "Title",                type: "string" },
      "inbox.id":            { label: "Inbox",                type: "lookup" },
      "inbox.name":          { label: "Inbox Name",           type: "string" },
      "inbox.channel_type":  { label: "Channel Type",         type: "enum" },
      "assignee.id":         { label: "Assigned Agent",       type: "lookup" },
      "assignee.name":       { label: "Agent Name",           type: "string" },
      "team.id":             { label: "Team",                 type: "lookup" },
      "team.name":           { label: "Team Name",            type: "string" },
      "customer.email":      { label: "Customer Email",       type: "string" },
      "customer.name":       { label: "Customer Name",        type: "string" },
      "customer.phone":      { label: "Customer Phone",       type: "string" },
      "message.content":     { label: "Message Content",      type: "string" },
      "message.sender_type": { label: "Message Sender Type",  type: "enum" },
      "labels":              { label: "Labels",               type: "list" },
      "hours_since_created":       { label: "Hours Since Created",       type: "number" },
      "hours_since_last_activity": { label: "Hours Since Last Activity", type: "number" },
    }
  }

  // Operators valid per attribute type
  get OPERATOR_SETS() {
    return {
      enum:   [["equals", "equals"], ["does not equal", "not_equals"]],
      string: [
        ["equals", "equals"], ["does not equal", "not_equals"],
        ["contains", "contains"], ["does not contain", "not_contains"],
        ["starts with", "starts_with"], ["ends with", "ends_with"],
        ["is present", "is_present"], ["is not present", "is_not_present"]
      ],
      number: [
        ["equals", "equals"], ["does not equal", "not_equals"],
        ["is greater than", "greater_than"], ["is less than", "less_than"],
        ["is present", "is_present"], ["is not present", "is_not_present"]
      ],
      lookup: [["equals", "equals"], ["does not equal", "not_equals"]],
      list:   [
        ["contains", "contains"], ["does not contain", "not_contains"],
        ["is present", "is_present"], ["is not present", "is_not_present"]
      ],
    }
  }

  // Which attributes are available per event
  get EVENT_ATTRIBUTES() {
    const conv = [
      "status", "priority", "source", "locale", "title",
      "inbox.id", "inbox.name", "inbox.channel_type",
      "assignee.id", "assignee.name", "team.id", "team.name",
      "customer.email", "customer.name", "labels"
    ]
    return {
      "conversation.created":        conv,
      "conversation.updated":        conv,
      "conversation.status_changed": conv,
      "conversation.assigned":       conv,
      "conversation.resolved":       conv,
      "message.created":  [...conv, "message.content", "message.sender_type"],
      "message.incoming": [...conv, "message.content"],
      "message.outgoing": [...conv, "message.content"],
      "customer.created": ["customer.email", "customer.name", "customer.phone", "source"],
      "customer.updated": ["customer.email", "customer.name", "customer.phone", "source"],
      "sla.breached":     ["status", "priority", "inbox.id", "assignee.id", "team.id", "labels"],
      "hours_since_created":       [...conv, "hours_since_created"],
      "hours_since_updated":       [...conv, "hours_since_created"],
      "hours_since_resolved":      [...conv, "hours_since_created"],
      "hours_since_last_activity": [...conv, "hours_since_last_activity"],
    }
  }

  // =========================================================================
  // Lifecycle
  // =========================================================================

  connect() {
    this.element.addEventListener("submit", this.serialize.bind(this))
    this._cache = {}
    this.updateDescriptionCounter()
  }

  updateDescriptionCounter() {
    if (!this.hasDescriptionInputTarget || !this.hasDescriptionCounterTarget) return
    this.descriptionCounterTarget.textContent = `${this.descriptionInputTarget.value.length} / 500`
  }

  setTopOperator(event) {
    const operator = event.currentTarget.dataset.operator
    if (this.hasTopOperatorFieldTarget) {
      this.topOperatorFieldTarget.value = operator
    }
    this._updatePillState(event.currentTarget.closest(".autom-match-row"), operator)
  }

  setGroupOperator(event) {
    const operator = event.currentTarget.dataset.operator
    const group = event.currentTarget.closest("[data-automation-builder-target='conditionGroup']")
    if (!group) return

    const hiddenField = group.querySelector("[data-condition-group-operator]")
    if (hiddenField) hiddenField.value = operator

    this._updatePillState(event.currentTarget.closest(".autom-group-pills"), operator)
  }

  _updatePillState(container, activeOperator) {
    if (!container) return
    container.querySelectorAll(".autom-pill").forEach(pill => {
      const isActive = pill.dataset.operator === activeOperator
      pill.classList.toggle("autom-pill--active", isActive)
    })
  }

  // =========================================================================
  // AJAX Lookups
  // =========================================================================

  async _fetchLookup(type, query = "", page = 1) {
    const cacheKey = `${type}:${query}:${page}`
    if (this._cache[cacheKey]) return this._cache[cacheKey]

    try {
      const params = new URLSearchParams({ type, page })
      if (query) params.set("q", query)

      const response = await fetch(`${this.lookupsUrlValue}?${params}`, {
        headers: { "Accept": "application/json" }
      })
      const data = await response.json()
      this._cache[cacheKey] = data
      return data
    } catch (e) {
      console.error(`Failed to fetch ${type}:`, e)
      return { results: [], has_more: false, total: 0 }
    }
  }

  _escapeHtml(str) {
    if (!str) return ""
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }

  // =========================================================================
  // Trigger
  // =========================================================================

  typeChanged(event) {
    const type = event.target.value
    const eventSelect = this.eventSelectTarget

    const eventTriggerEvents = [
      ["Conversation Created", "conversation.created"],
      ["Conversation Updated", "conversation.updated"],
      ["Conversation Status Changed", "conversation.status_changed"],
      ["Conversation Assigned", "conversation.assigned"],
      ["Conversation Resolved", "conversation.resolved"],
      ["Message Created", "message.created"],
      ["Incoming Message", "message.incoming"],
      ["Outgoing Message", "message.outgoing"],
      ["Customer Created", "customer.created"],
      ["Customer Updated", "customer.updated"],
      ["SLA Breached", "sla.breached"]
    ]

    const timeTriggerEvents = [
      ["Hours Since Created", "hours_since_created"],
      ["Hours Since Updated", "hours_since_updated"],
      ["Hours Since Resolved", "hours_since_resolved"],
      ["Hours Since Last Activity", "hours_since_last_activity"]
    ]

    const events = type === "time_trigger" ? timeTriggerEvents : eventTriggerEvents

    eventSelect.innerHTML = '<option value="">Select event...</option>'
    events.forEach(([label, value]) => {
      const opt = document.createElement("option")
      opt.value = value
      opt.textContent = label
      eventSelect.appendChild(opt)
    })

    this._refreshAllAttributeDropdowns()
  }

  // When event is selected, refresh attribute dropdowns
  eventChanged(_event) {
    this._refreshAllAttributeDropdowns()
  }

  // =========================================================================
  // Conditions
  // =========================================================================

  addConditionGroup() {
    const container = this.conditionGroupsTarget
    const groupIndex = container.querySelectorAll("[data-automation-builder-target='conditionGroup']").length
    container.insertAdjacentHTML("beforeend", this._conditionGroupTemplate(groupIndex))
  }

  removeConditionGroup(event) {
    const group = event.target.closest("[data-automation-builder-target='conditionGroup']")
    if (group) group.remove()
  }

  addCondition(event) {
    const groupIndex = event.target.dataset.groupIndex || 0
    const group = event.target.closest("[data-automation-builder-target='conditionGroup']")
    const rowsContainer = group.querySelector("[data-condition-group-rows]")
    const condIndex = rowsContainer.querySelectorAll("[data-condition-row]").length
    rowsContainer.insertAdjacentHTML("beforeend", this._conditionRowTemplate(groupIndex, condIndex))
  }

  removeCondition(event) {
    const row = event.target.closest("[data-condition-row]")
    if (row) row.remove()
  }

  // Attribute selected → cascade operator dropdown + value field
  async attributeChanged(event) {
    const row = event.target.closest("[data-condition-row]")
    const attribute = event.target.value

    // Update operator dropdown to show only valid operators
    const opContainer = row.querySelector("[data-condition-op-container]")
    if (opContainer) {
      opContainer.innerHTML = `<select data-controller="select" data-condition-op class="ui-select ui-control">${this._operatorsForAttribute(attribute)}</select>`
    }

    // Update value field to match attribute type
    const valueContainer = row.querySelector("[data-condition-value-container]")
    if (valueContainer) {
      valueContainer.innerHTML = await this._conditionValueField(attribute)
    }
  }

  // =========================================================================
  // Actions
  // =========================================================================

  addAction() {
    const container = this.actionRowsTarget
    const actionIndex = container.querySelectorAll("[data-action-row]").length
    container.insertAdjacentHTML("beforeend", this._actionRowTemplate(actionIndex))
  }

  removeAction(event) {
    const row = event.target.closest("[data-action-row]")
    if (row) row.remove()
  }

  async actionTypeChanged(event) {
    const row = event.target.closest("[data-action-row]")
    const paramsContainer = row.querySelector("[data-action-params]")
    paramsContainer.innerHTML = ""
    paramsContainer.innerHTML = await this._actionParamsTemplate(event.target.value)
  }

  // =========================================================================
  // Serialization
  // =========================================================================

  serialize(_event) {
    if (this.hasConditionsFieldTarget && this.hasConditionsContainerTarget && this.hasConditionGroupsTarget) {
      const topOperator = this.conditionsContainerTarget.querySelector("[name*='[conditions][operator]']")
      const groups = this.conditionGroupsTarget.querySelectorAll("[data-automation-builder-target='conditionGroup']")

      const conditionsJson = {
        operator: topOperator ? topOperator.value : "AND",
        groups: Array.from(groups).map(group => {
          const groupOp = group.querySelector("[data-condition-group-operator]")
          const rows = group.querySelectorAll("[data-condition-row]")
          return {
            operator: groupOp ? groupOp.value : "AND",
            conditions: Array.from(rows).map(row => ({
              attribute: row.querySelector("[data-condition-attr]")?.value || "",
              operator:  row.querySelector("[data-condition-op]")?.value || "",
              value:     row.querySelector("[data-condition-val]")?.value || ""
            })).filter(c => c.attribute && c.operator)
          }
        }).filter(g => g.conditions.length > 0)
      }
      this.conditionsFieldTarget.value = JSON.stringify(conditionsJson)
    }

    if (this.hasActionsFieldTarget && this.hasActionRowsTarget) {
      const actionRows = this.actionRowsTarget.querySelectorAll("[data-action-row]")
      const actionsJson = Array.from(actionRows).map(row => {
        const actionType = row.querySelector("[data-action-type]")?.value || ""
        const params = {}
        row.querySelectorAll("[data-action-param]").forEach(el => {
          if (el.dataset.actionParam && el.value) params[el.dataset.actionParam] = el.value
        })
        return { action: actionType, params }
      }).filter(a => a.action)
      this.actionsFieldTarget.value = JSON.stringify(actionsJson)
    }
  }

  // =========================================================================
  // Cascading Helpers
  // =========================================================================

  _currentEventName() {
    return this.hasEventSelectTarget ? (this.eventSelectTarget.value || null) : null
  }

  // Returns [label, key] pairs filtered by the current event
  _attributesForCurrentEvent() {
    const event = this._currentEventName()
    const allowed = event ? this.EVENT_ATTRIBUTES[event] : null
    const registry = this.ATTRIBUTE_REGISTRY
    const keys = allowed || Object.keys(registry)
    return keys.filter(k => registry[k]).map(k => [registry[k].label, k])
  }

  // Returns <option> HTML for operators valid for the given attribute
  _operatorsForAttribute(attribute) {
    const attrType = this.ATTRIBUTE_REGISTRY[attribute]?.type || "string"
    const ops = this.OPERATOR_SETS[attrType] || this.OPERATOR_SETS.string
    return '<option value="">Select operator...</option>' +
      ops.map(([label, val]) => `<option value="${val}">${label}</option>`).join("")
  }

  // Refreshes all attribute <select>s in the conditions section
  _refreshAllAttributeDropdowns() {
    if (!this.hasConditionGroupsTarget) return

    const attrs = this._attributesForCurrentEvent()

    this.conditionGroupsTarget.querySelectorAll("[data-condition-attr-container]").forEach(container => {
      const select = container.querySelector("[data-condition-attr]")
      const current = select.value
      const selectedOptions = attrs.map(([label, val]) =>
        `<option value="${val}"${val === current ? " selected" : ""}>${label}</option>`
      ).join("")
      container.innerHTML = `<select data-controller="select" data-condition-attr data-action="change->automation-builder#attributeChanged" class="ui-select ui-control"><option value="">Select attribute...</option>${selectedOptions}</select>`
    })
  }

  // =========================================================================
  // Condition Value Field
  // =========================================================================

  async _conditionValueField(attribute, currentValue = "") {
    const fixedOptions = {
      "status":              [["Active", "active"], ["Closed", "closed"], ["Snoozed", "snoozed"], ["Resolved", "resolved"]],
      "priority":            [["Low", "low"], ["Medium", "medium"], ["High", "high"], ["Urgent", "urgent"]],
      "source":              [["Web Widget", "web_widget"], ["Email", "email"], ["API", "api"], ["Facebook", "facebook"], ["WhatsApp", "whatsapp"]],
      "inbox.channel_type":  [["Web Widget", "Channel::WebWidget"], ["Email", "Channel::Email"], ["Facebook", "Channel::FacebookPage"], ["WhatsApp", "Channel::Whatsapp"]],
      "message.sender_type": [["Customer", "Customer"], ["User", "User"]],
    }

    if (fixedOptions[attribute]) {
      const opts = fixedOptions[attribute].map(([label, val]) =>
        `<option value="${val}"${val === currentValue ? " selected" : ""}>${label}</option>`
      ).join("")
      return `<select data-controller="select" data-condition-val class="ui-select ui-control"><option value="">Select...</option>${opts}</select>`
    }

    const ajaxTypes = { "inbox.id": "inboxes", "assignee.id": "agents", "team.id": "teams", "labels": "labels" }
    if (ajaxTypes[attribute]) {
      const data = await this._fetchLookup(ajaxTypes[attribute])
      const opts = data.results.map(item =>
        `<option value="${item.id}"${String(item.id) === String(currentValue) ? " selected" : ""}>${this._escapeHtml(item.name)}</option>`
      ).join("")
      const hint = data.has_more ? ` <small style="color:#94a3b8;">(${data.total} total)</small>` : ""
      return `<select data-controller="select" data-condition-val class="ui-select ui-control"><option value="">Select...</option>${opts}</select>${hint}`
    }

    return `<input type="text" data-condition-val placeholder="Value..." value="${this._escapeHtml(currentValue)}" class="ap-input">`
  }

  // =========================================================================
  // Action Params Template
  // =========================================================================

  async _actionParamsTemplate(actionType) {
    switch (actionType) {
      case "assign_agent": {
        const d = await this._fetchLookup("agents")
        const o = d.results.map(a => `<option value="${a.id}">${this._escapeHtml(a.name)}</option>`).join("")
        return `<select data-controller="select" data-action-param="agent_id" class="ui-select ui-control"><option value="">Select agent...</option>${o}</select>`
      }
      case "assign_team": {
        const d = await this._fetchLookup("teams")
        const o = d.results.map(t => `<option value="${t.id}">${this._escapeHtml(t.name)}</option>`).join("")
        return `<select data-controller="select" data-action-param="team_id" class="ui-select ui-control"><option value="">Select team...</option>${o}</select>`
      }
      case "add_label":
      case "remove_label": {
        const d = await this._fetchLookup("labels")
        const o = d.results.map(l => `<option value="${l.id}">${this._escapeHtml(l.name)}</option>`).join("")
        return `<select data-controller="select" data-action-param="label_ids" class="ui-select ui-control autom-label-select"><option value="">Select label...</option>${o}</select>`
      }
      case "set_status":
        return `<select data-controller="select" data-action-param="status" class="ui-select ui-control">
          <option value="active">Active</option><option value="closed">Closed</option>
          <option value="snoozed">Snoozed</option><option value="resolved">Resolved</option></select>`
      case "set_priority":
        return `<select data-controller="select" data-action-param="priority" class="ui-select ui-control">
          <option value="low">Low</option><option value="medium">Medium</option>
          <option value="high">High</option><option value="urgent">Urgent</option></select>`
      case "send_message":
      case "add_note":
        return `<textarea data-action-param="content" placeholder="Enter message..." rows="4" class="ap-input autom-action-textarea"></textarea>`
      case "snooze":
        return `<input type="number" data-action-param="duration_hours" placeholder="Hours" min="1" class="ap-input">`
      case "set_locale":
        return `<input type="text" data-action-param="locale" placeholder="e.g. en, fr, de" class="ap-input">`
      case "set_custom_field":
        return `<input type="text" data-action-param="key" placeholder="Field key" class="ap-input" style="flex:1">
          <input type="text" data-action-param="value" placeholder="Value" class="ap-input" style="flex:1">`
      case "trigger_webhook":
        return `<input type="text" data-action-param="url" placeholder="https://..." class="ap-input">
          <select data-controller="select" data-action-param="method" class="ui-select ui-control">
            <option value="POST">POST</option><option value="GET">GET</option>
            <option value="PUT">PUT</option><option value="PATCH">PATCH</option></select>`
      case "unassign":
      case "resolve":
      case "mute_conversation":
        return ""
      default:
        return `<input type="text" data-action-param="value" placeholder="Value..." class="ap-input">`
    }
  }

  // =========================================================================
  // HTML Templates
  // =========================================================================

  _conditionGroupTemplate(groupIndex) {
    return `
      <div class="autom-condition-group" data-automation-builder-target="conditionGroup">
        <div class="autom-group-header ui-responsive-wrap-mobile">
          <span class="autom-group-label">Group ${groupIndex + 1}</span>
          <div class="autom-group-pills">
            <button type="button" class="autom-pill autom-pill--sm autom-pill--active" data-action="click->automation-builder#setGroupOperator" data-operator="AND" data-group-index="${groupIndex}">All</button>
            <button type="button" class="autom-pill autom-pill--sm" data-action="click->automation-builder#setGroupOperator" data-operator="OR" data-group-index="${groupIndex}">Any</button>
          </div>
          <input type="hidden" data-condition-group-operator value="AND">
          <button type="button" class="autom-remove-group-btn" data-action="click->automation-builder#removeConditionGroup" title="Remove group">
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none" aria-hidden="true" xmlns="http://www.w3.org/2000/svg"><path d="M2 4h12v8H2zM4 6h8v4H4z" stroke="#94a3b8" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </button>
        </div>
        <div data-condition-group-rows>
          ${this._conditionRowTemplate(groupIndex, 0)}
        </div>
        <button type="button" class="autom-add-condition-link" data-action="click->automation-builder#addCondition" data-group-index="${groupIndex}">
          + Add Condition
        </button>
      </div>
    `
  }

  _conditionRowTemplate(groupIndex, condIndex) {
    const attrs = this._attributesForCurrentEvent()
    const attrOptions = attrs.map(([label, val]) => `<option value="${val}">${label}</option>`).join("")

    return `
      <div class="autom-condition-row" data-condition-row>
        <div class="ui-field-control ui-field-control--plain ui-field-control--no-icon" data-condition-attr-container style="flex: 1; min-width: 0;">
          <select data-controller="select" data-condition-attr data-action="change->automation-builder#attributeChanged" class="ui-select ui-control">
            <option value="">Select attribute...</option>
            ${attrOptions}
          </select>
        </div>
        <div class="ui-field-control ui-field-control--plain ui-field-control--no-icon" data-condition-op-container style="flex: 1; min-width: 0;">
          <select data-controller="select" data-condition-op class="ui-select ui-control">
            <option value="">Select attribute first...</option>
          </select>
        </div>
        <span class="ui-field-control ui-field-control--plain ui-field-control--no-icon" data-condition-value-container style="flex: 1; min-width: 0;">
          <input type="text" data-condition-val placeholder="Select attribute first..." class="ap-input" disabled>
        </span>
        <button type="button" class="autom-remove-condition-btn" data-action="click->automation-builder#removeCondition" aria-label="Remove condition">
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none" aria-hidden="true" xmlns="http://www.w3.org/2000/svg"><path d="M12.666 4.667l-.578 8.094A1.333 1.333 0 0110.758 14H5.241a1.333 1.333 0 01-1.33-1.239l-.578-8.094M6.666 7.333v4M9.333 7.333v4M10 4.667v-2A.667.667 0 009.333 2H6.666A.667.667 0 006 2.667v2M2.666 4.667h10.667" stroke="#EF4444" stroke-width="1.333" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
      </div>
    `
  }

  _actionRowTemplate(actionIndex) {
    return `
      <div class="autom-action-row" data-action-row>
        <div class="ui-field-control ui-field-control--plain ui-field-control--no-icon ui-macro-action-select">
          <select data-controller="select" data-action-type data-action="change->automation-builder#actionTypeChanged" class="ui-select ui-control">
            <option value="">Select action...</option>
            ${this._actionOptions()}
          </select>
        </div>
        <span class="ui-field-control ui-field-control--plain ui-field-control--no-icon" data-action-params></span>
        <button type="button" class="autom-remove-action-btn ui-macro-remove-action" data-action="click->automation-builder#removeAction" aria-label="Delete action">
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true" xmlns="http://www.w3.org/2000/svg">
            <path d="M12.666 4.667l-.578 8.094A1.333 1.333 0 0110.758 14H5.241a1.333 1.333 0 01-1.33-1.239l-.578-8.094M6.666 7.333v4M9.333 7.333v4M10 4.667v-2A.667.667 0 009.333 2H6.666A.667.667 0 006 2.667v2M2.666 4.667h10.667" stroke="#EF4444" stroke-width="1.333" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </button>
      </div>
    `
  }

  _actionOptions() {
    return [
      ["Assign to Agent", "assign_agent"], ["Assign to Team", "assign_team"],
      ["Unassign", "unassign"], ["Set Status", "set_status"],
      ["Set Priority", "set_priority"], ["Add Label", "add_label"],
      ["Remove Label", "remove_label"], ["Set Custom Field", "set_custom_field"],
      ["Send Message", "send_message"], ["Send Email to Customer", "send_email_to_customer"],
      ["Add Internal Note", "add_note"], ["Snooze", "snooze"],
      ["Resolve", "resolve"], ["Mute Conversation", "mute_conversation"],
      ["Trigger Webhook", "trigger_webhook"], ["Set Locale", "set_locale"]
    ].map(([label, val]) => `<option value="${val}">${label}</option>`).join("")
  }
}
