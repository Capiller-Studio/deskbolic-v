import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkbox", "jsonOutput", "preset" ]

  connect() {
    this.serialize()
  }

  toggle(event) {
    if (this.hasPresetTarget) {
      this.presetTargets.forEach((preset) => { preset.checked = false })
    }
    this.serialize()
  }

  applyPreset(event) {
    let permissions = {}

    try {
      permissions = JSON.parse(event.currentTarget.dataset.permissions || "{}")
    } catch (_error) {
      permissions = {}
    }

    this.checkboxTargets.forEach((checkbox) => {
      const resourcePermissions = permissions[checkbox.dataset.resource] || {}
      checkbox.checked = resourcePermissions[checkbox.dataset.permissionAction] === true
    })

    this.serialize()
  }

  serialize() {
    const permissions = {}

    this.checkboxTargets.forEach((checkbox) => {
      if (checkbox.checked) {
        // We use data-resource="conversations" data-action="read"
        const resource = checkbox.dataset.resource
        const action = checkbox.dataset.permissionAction

        if (!permissions[resource]) {
          permissions[resource] = {}
        }
        permissions[resource][action] = true
      }
    })

    this.jsonOutputTarget.value = JSON.stringify(permissions)
  }
}
