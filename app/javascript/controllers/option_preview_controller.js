import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "template", "output"]
  static values = {
    previewLimit: { type: Number, default: 4 },
    moreLabel: { type: String, default: "And __COUNT__ more" },
    showLessLabel: { type: String, default: "Show less" },
    noPermissionsLabel: { type: String, default: "No permissions assigned" }
  }

  connect() {
    this.renderSelection()
  }

  select() {
    this.renderSelection()
  }

  expand() {
    this.setExpanded(true)
  }

  collapse() {
    this.setExpanded(false)
  }

  renderSelection() {
    const selectedKeys = this.optionTargets
      .filter((option) => option.checked)
      .map((option) => option.value)
    const permissionElements = new Map()

    selectedKeys.forEach((key) => {
      const template = this.templateTargets.find((candidate) => candidate.dataset.key === key)
      if (!template) return

      template.content.querySelectorAll("[data-option-preview-permission]").forEach((element) => {
        const permissionKey = element.dataset.permissionKey || element.textContent.trim()
        if (!permissionElements.has(permissionKey)) {
          permissionElements.set(permissionKey, element.cloneNode(true))
        }
      })
    })

    const fragment = document.createDocumentFragment()
    const permissions = Array.from(permissionElements.values())

    if (permissions.length === 0) {
      const empty = document.createElement("span")
      empty.className = "tm-permission tm-permission-empty"
      empty.textContent = this.noPermissionsLabelValue
      fragment.appendChild(empty)
    } else {
      permissions.forEach((permission, index) => {
        if (index >= this.previewLimitValue) {
          permission.hidden = true
          permission.dataset.optionPreviewOverflow = "true"
        }
        fragment.appendChild(permission)
      })
    }

    const remainingCount = Math.max(permissions.length - this.previewLimitValue, 0)
    if (remainingCount > 0) {
      fragment.appendChild(this.toggleButton(
        this.moreLabelValue.replace("__COUNT__", remainingCount),
        "expand"
      ))
      fragment.appendChild(this.toggleButton(this.showLessLabelValue, "collapse", true))
    }

    this.outputTarget.replaceChildren(fragment)
  }

  setExpanded(expanded) {
    this.outputTarget.querySelectorAll("[data-option-preview-overflow]").forEach((element) => {
      element.hidden = !expanded
    })

    this.outputTarget.querySelectorAll("[data-option-preview-expand]").forEach((element) => {
      element.hidden = expanded
    })

    this.outputTarget.querySelectorAll("[data-option-preview-collapse]").forEach((element) => {
      element.hidden = !expanded
    })
  }

  toggleButton(label, action, hidden = false) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "tm-permission tm-permission-more"
    button.textContent = label
    button.hidden = hidden
    button.dataset[`optionPreview${action[0].toUpperCase()}${action.slice(1)}`] = "true"
    button.dataset.action = `option-preview#${action}`
    return button
  }
}
