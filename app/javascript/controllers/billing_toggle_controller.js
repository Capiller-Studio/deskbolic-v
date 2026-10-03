import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "toggle",
    "price",
    "period",
    "cycleField",
    "monthlyLabel",
    "yearlyLabel",
    "annualNote",
    "seatBlock",
    "seatInput",
    "seatTotal"
  ]

  connect() {
    this.updateAllTotals()
  }

  toggle() {
    const isAnnual = this.toggleTarget.checked

    // Update labels
    if (this.hasMonthlyLabelTarget && this.hasYearlyLabelTarget) {
      this.monthlyLabelTarget.classList.toggle("ap-billing-cycle-active", !isAnnual)
      this.yearlyLabelTarget.classList.toggle("ap-billing-cycle-active", isAnnual)
    }

    // Update all price displays
    this.priceTargets.forEach((priceEl) => {
      const monthlyPrice = parseFloat(priceEl.dataset.monthlyPrice) || 0
      const annualPrice = parseFloat(priceEl.dataset.annualPrice) || 0
      const currency = priceEl.dataset.currency || "USD"

      const displayPrice = isAnnual && annualPrice > 0 ? annualPrice : monthlyPrice
      priceEl.textContent = `${currency} ${this.formatCurrency(displayPrice, currency)}`
    })

    // Update period labels
    this.periodTargets.forEach((periodEl) => {
      periodEl.textContent = "/mo"
    })

    // Toggle annual note visibility
    this.annualNoteTargets.forEach((noteEl) => {
      noteEl.style.display = isAnnual ? "block" : "block"
    })

    // Update all hidden billing_cycle fields
    this.cycleFieldTargets.forEach((field) => {
      field.value = isAnnual ? "annual" : "monthly"
    })

    // Update all seat total calculations
    this.updateAllTotals()
  }

  incrementSeats(event) {
    const block = event.currentTarget.closest(".ap-subscription-seats-block")
    if (!block) return

    const input = block.querySelector(".ap-subscription-seats-input")
    if (!input || input.readOnly) return

    const min = parseInt(block.dataset.minSeats, 10) || 1
    const max = block.dataset.maxSeats ? parseInt(block.dataset.maxSeats, 10) : null
    let val = parseInt(input.value, 10) || min

    if (max === null || val < max) {
      val += 1
      input.value = val
      this.updateBlockUI(block, true)
    }
  }

  decrementSeats(event) {
    const block = event.currentTarget.closest(".ap-subscription-seats-block")
    if (!block) return

    const input = block.querySelector(".ap-subscription-seats-input")
    if (!input || input.readOnly) return

    const min = parseInt(block.dataset.minSeats, 10) || 1
    let val = parseInt(input.value, 10) || min

    if (val > min) {
      val -= 1
      input.value = val
      this.updateBlockUI(block, true)
    }
  }

  changeSeats(event) {
    const block = event.currentTarget.closest(".ap-subscription-seats-block")
    if (!block) return
    this.updateBlockUI(block, false)
  }

  clampSeats(event) {
    const block = event.currentTarget.closest(".ap-subscription-seats-block")
    if (!block) return
    this.updateBlockUI(block, true)
  }

  updateBlockUI(block, clamp = false) {
    const input = block.querySelector(".ap-subscription-seats-input")
    if (!input) return

    const min = parseInt(block.dataset.minSeats, 10) || 1
    const max = block.dataset.maxSeats ? parseInt(block.dataset.maxSeats, 10) : null
    let val = parseInt(input.value, 10)

    if (isNaN(val)) {
      if (clamp) {
        val = min
        input.value = val
      } else {
        return
      }
    }

    if (clamp) {
      if (val < min) val = min
      if (max !== null && val > max) val = max
      input.value = val
    }

    // Update buttons
    const decBtn = block.querySelector(".ap-subscription-seats-btn--decrement")
    const incBtn = block.querySelector(".ap-subscription-seats-btn--increment")
    if (decBtn) decBtn.disabled = val <= min || input.readOnly
    if (incBtn) incBtn.disabled = (max !== null && val >= max) || input.readOnly

    // Update total display
    const totalEl = block.querySelector("[data-billing-toggle-target='seatTotal']")
    if (totalEl) {
      const isAnnual = this.toggleTarget ? this.toggleTarget.checked : false
      const monthlyPrice = parseFloat(block.dataset.monthlyPrice) || 0
      const annualPrice = parseFloat(block.dataset.annualPrice) || 0
      const currency = block.dataset.currency || "USD"
      const unitPrice = isAnnual && annualPrice > 0 ? annualPrice : monthlyPrice

      if (unitPrice === 0) {
        totalEl.textContent = `${currency} 0 /mo`
      } else {
        const total = val * unitPrice
        totalEl.textContent = `${currency} ${this.formatCurrency(total, currency)} /mo`
      }
    }
  }

  updateAllTotals() {
    if (!this.hasSeatBlockTargets) return
    this.seatBlockTargets.forEach((block) => {
      this.updateBlockUI(block, false)
    })
  }

  formatCurrency(amount, currency) {
    if (amount === 0) return "0"
    if (currency === "KRW" || Number.isInteger(amount)) {
      return amount.toLocaleString("en-US", { minimumFractionDigits: 0, maximumFractionDigits: 0 })
    }
    return amount.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
