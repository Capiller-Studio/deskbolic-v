import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "filter", "sort", "container", "item", "empty"]

  connect() {
    this.selectedFilter = ""
    this.update()
  }

  selectFilter(event) {
    this.selectedFilter = event.currentTarget.dataset.filterValue || ""
    this.update()
  }

  update() {
    const query = this.hasQueryTarget ? this.queryTarget.value.trim().toLowerCase() : ""
    const filter = this.selectedFilter || (this.hasFilterTarget ? this.filterTarget.value : "")
    let visibleCount = 0

    this.element.classList.toggle("filterable-collection-searching", query.length > 0)

    this.itemTargets.forEach((item) => {
      const searchableText = (item.dataset.searchable || "").toLowerCase()
      const filterValues = (item.dataset.filterValues || "").split(",").filter(Boolean)
      const matchesQuery = !query || searchableText.includes(query)
      const matchesFilter = !filter || filterValues.includes(filter)
      const visible = matchesQuery && matchesFilter

      item.hidden = !visible
      item.style.display = visible ? "" : "none"
      if (visible) visibleCount += 1
    })

    this.updateAccordionPanels(query)
    this.sortItems()
    if (this.hasEmptyTarget) {
      const emptyHidden = visibleCount > 0
      this.emptyTarget.hidden = emptyHidden
      this.emptyTarget.style.display = emptyHidden ? "none" : ""
    }
  }

  updateAccordionPanels(query) {
    const searching = query.length > 0
    const itemSelector = '[data-filterable-collection-target~="item"]'

    const panels = this.element.querySelectorAll('[data-accordion-target~="panel"]')

    panels.forEach((panel) => {
      const panelItems = [...panel.querySelectorAll(itemSelector)]
      const hasMatchingItem = panelItems.some((item) => !item.hidden)
      const showSearchResults = searching && hasMatchingItem
      const trigger = panel.previousElementSibling

      panel.classList.toggle(
        "filterable-collection-panel-match",
        showSearchResults
      )

      if (!trigger?.matches(itemSelector)) return

      if (searching) {
        trigger.hidden = !showSearchResults
        trigger.style.display = showSearchResults ? "" : "none"
      }

      trigger.classList.toggle(
        "filterable-collection-expanded",
        showSearchResults
      )
      trigger.setAttribute(
        "aria-expanded",
        (panel.classList.contains("visible") || showSearchResults).toString()
      )
    })
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
