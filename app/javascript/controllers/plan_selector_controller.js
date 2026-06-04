import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "radio", "minSeats", "maxSeats", "quantityInput", "planLimitText"]
  
  connect() {
    this.updateHighlight()
  }

  select(event) {
    // If the click originated from a radio button, just highlight
    if (event.target.type === 'radio') {
      this.updateHighlight()
      return
    }

    // Otherwise, find the radio button within the clicked card and check it
    const radio = event.currentTarget.querySelector('input[type="radio"]')
    if (radio) {
      radio.checked = true
      this.updateHighlight()
    }
  }

  updateHighlight() {
    this.cardTargets.forEach((card, index) => {
      const radio = this.radioTargets[index]
      if (radio.checked) {
        card.style.borderColor = '#4f46e5'
        
        // Update max/min limits on the quantity input
        if (this.hasQuantityInputTarget) {
          const minVal = parseInt(radio.dataset.minUsers)
          const maxVal = parseInt(radio.dataset.maxUsers)
          const currentUsers = parseInt(this.quantityInputTarget.dataset.currentUsers)
          
          this.quantityInputTarget.min = minVal
          
          let limitText = ""
          if (maxVal > -1) {
            this.quantityInputTarget.max = maxVal
            limitText = `Limits: Min ${minVal}, Max ${maxVal}`
          } else {
            this.quantityInputTarget.removeAttribute('max')
            limitText = `Limits: Min ${minVal}, Max Unlimited`
          }

          if (maxVal > -1 && currentUsers > maxVal) {
            this.planLimitTextTarget.innerHTML = `<span class="text-red-500">You have ${currentUsers} active users. Remove ${currentUsers - maxVal} to select this plan.</span>`
            this.element.querySelector('input[type="submit"]').disabled = true
            this.element.querySelector('input[type="submit"]').classList.add('opacity-50', 'cursor-not-allowed')
          } else {
            this.planLimitTextTarget.textContent = limitText
            this.element.querySelector('input[type="submit"]').disabled = false
            this.element.querySelector('input[type="submit"]').classList.remove('opacity-50', 'cursor-not-allowed')
          }
          
          // clamp current value if needed
          if (parseInt(this.quantityInputTarget.value) < Math.max(minVal, currentUsers)) {
            this.quantityInputTarget.value = Math.max(minVal, currentUsers)
          } else if (maxVal > -1 && parseInt(this.quantityInputTarget.value) > maxVal) {
            this.quantityInputTarget.value = maxVal
          }
        }
      } else {
        card.style.borderColor = '#e2e8f0'
      }
    })
  }
}
