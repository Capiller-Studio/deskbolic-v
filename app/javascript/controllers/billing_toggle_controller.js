import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "price", "period", "cycleField", "monthlyLabel", "yearlyLabel", "annualNote"]

  toggle() {
    const isAnnual = this.toggleTarget.checked

    // Update labels
    if (this.hasMonthlyLabelTarget && this.hasYearlyLabelTarget) {
      this.monthlyLabelTarget.classList.toggle("ap-billing-cycle-active", !isAnnual)
      this.yearlyLabelTarget.classList.toggle("ap-billing-cycle-active", isAnnual)
    }

    // Update all price displays
    this.priceTargets.forEach((priceEl) => {
      const monthlyPrice = parseFloat(priceEl.dataset.monthlyPrice)
      const annualPrice = parseFloat(priceEl.dataset.annualPrice)
      const currency = priceEl.dataset.currency || "USD"

      const displayPrice = isAnnual ? annualPrice : monthlyPrice
      priceEl.textContent = `${currency} ${this.formatCurrency(displayPrice, currency)}`
    })

    // Update period labels
    this.periodTargets.forEach((periodEl) => {
      periodEl.textContent = isAnnual ? "/mo (billed yearly)" : "/mo"
    })

    // Toggle annual note visibility
    this.annualNoteTargets.forEach((noteEl) => {
      noteEl.style.display = isAnnual ? "block" : "none"
    })

    // Update all hidden billing_cycle fields
    this.cycleFieldTargets.forEach((field) => {
      field.value = isAnnual ? "annual" : "monthly"
    })
  }

  formatCurrency(amount, currency) {
    if (amount === 0) return "0"
    if (currency === "KRW") {
      return amount.toLocaleString("en-US", { minimumFractionDigits: 0 })
    }
    return amount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
