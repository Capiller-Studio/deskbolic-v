import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "filter", "sort", "container", "item", "empty"]

  connect() {
    this.update()
  }

  update() {
    const query = this.hasQueryTarget ? this.queryTarget.value.trim().toLowerCase() : ""
    const filter = this.hasFilterTarget ? this.filterTarget.value : ""
    let visibleCount = 0

    this.itemTargets.forEach((item) => {
      const searchableText = (item.dataset.searchable || "").toLowerCase()
      const filterValues = (item.dataset.filterValues || "").split(",").filter(Boolean)
      const matchesQuery = !query || searchableText.includes(query)
      const matchesFilter = !filter || filterValues.includes(filter)

      item.hidden = !(matchesQuery && matchesFilter)
      if (!item.hidden) visibleCount += 1
    })

    this.sortItems()
    if (this.hasEmptyTarget) this.emptyTarget.hidden = visibleCount > 0
  }

  sortItems() {
    if (!this.hasSortTarget || !this.hasContainerTarget) return

    const [field, direction = "asc"] = this.sortTarget.value.split(":")
    const multiplier = direction === "desc" ? -1 : 1

    const items = [...this.itemTargets].sort((a, b) => {
      const left = a.dataset[field] || ""
      const right = b.dataset[field] || ""
      const numeric = Number(left) - Number(right)
      const comparison = Number.isNaN(numeric) ? left.localeCompare(right) : numeric

      return comparison * multiplier
    })

    items.forEach((item) => this.containerTarget.append(item))
  }
}
