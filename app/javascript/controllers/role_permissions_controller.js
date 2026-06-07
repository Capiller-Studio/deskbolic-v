import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "checkbox", "jsonOutput" ]

  connect() {
    this.serialize()
  }

  toggle(event) {
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
