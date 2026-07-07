import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slotTemplate", "exceptionTemplate", "slotsContainer", "exceptionsContainer", "slot", "exceptionSlot", "destroyInput"]

  connect() {
    this.newRecordIndex = new Date().getTime()
    
    // Initialize toggles state on load
    this.slotsContainerTargets.forEach(container => {
      const dayIndex = container.dataset.dayIndex
      const toggle = this.element.querySelector(`input[name="day_enabled_${dayIndex}"]`)
      if (toggle) {
        // Trigger the toggle logic to set opacity/pointer-events without adding new slots
        const isEnabled = toggle.checked
        if (isEnabled) {
          container.style.opacity = "1"
          container.style.pointerEvents = "auto"
        } else {
          container.style.opacity = "0.5"
          container.style.pointerEvents = "none"
        }
      }
    })
  }

  addSlot(event) {
    const dayIndex = event.currentTarget.dataset.dayIndex
    const container = this.slotsContainerTargets.find(el => el.dataset.dayIndex === dayIndex)
    
    if (container) {
      const dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
      const dayName = dayNames[dayIndex]
      
      let content = this.slotTemplateTarget.innerHTML
      content = content.replace(/NEW_RECORD/g, this.newRecordIndex++)
      content = content.replace(/DAY_NAME/g, dayName)
      
      container.insertAdjacentHTML('beforeend', content)
      
      // Ensure the toggle is checked if they manually add a slot
      const toggle = this.element.querySelector(`input[name="day_enabled_${dayIndex}"]`)
      if (toggle && !toggle.checked) {
        toggle.checked = true
        this.toggleDay({ currentTarget: toggle, dataset: { dayIndex: dayIndex } })
      }
    }
  }

  removeSlot(event) {
    const slot = event.currentTarget.closest('[data-business-hours-target="slot"]')
    const destroyInput = slot.querySelector('[data-business-hours-target="destroyInput"]')
    
    if (destroyInput) {
      destroyInput.value = "1"
      slot.style.display = "none"
    } else {
      slot.remove()
    }
  }

  toggleDay(event) {
    const dayIndex = event.currentTarget.dataset.dayIndex || event.dataset.dayIndex
    const isEnabled = event.currentTarget ? event.currentTarget.checked : event.checked
    const container = this.slotsContainerTargets.find(el => el.dataset.dayIndex === dayIndex)
    
    if (container) {
      if (isEnabled) {
        container.style.opacity = "1"
        container.style.pointerEvents = "auto"
        // If they enable it but it's empty, add a default slot
        const visibleSlots = Array.from(container.querySelectorAll('[data-business-hours-target="slot"]'))
          .filter(slot => slot.style.display !== 'none')
        if (visibleSlots.length === 0) {
          this.addSlot({ currentTarget: { dataset: { dayIndex: dayIndex } } })
        }
      } else {
        container.style.opacity = "0.5"
        container.style.pointerEvents = "none"
        
        // Mark all existing slots for destruction
        const slots = container.querySelectorAll('[data-business-hours-target="slot"]')
        slots.forEach(slot => {
          const destroyInput = slot.querySelector('[data-business-hours-target="destroyInput"]')
          if (destroyInput) {
            destroyInput.value = "1"
            slot.style.display = "none"
          } else {
            slot.remove()
          }
        })
      }
    }
  }

  addExceptionSlot(event) {
    let content = this.exceptionTemplateTarget.innerHTML
    content = content.replace(/NEW_RECORD/g, this.newRecordIndex++)
    this.exceptionsContainerTarget.insertAdjacentHTML('beforeend', content)
  }

  removeExceptionSlot(event) {
    const slot = event.currentTarget.closest('[data-business-hours-target="exceptionSlot"]')
    const destroyInput = slot.querySelector('[data-business-hours-target="destroyInput"]')
    
    if (destroyInput) {
      destroyInput.value = "1"
      slot.style.display = "none"
    } else {
      slot.remove()
    }
  }

  validateTime(event) {
    const input = event.currentTarget
    const slot = input.closest('[data-business-hours-target="slot"], [data-business-hours-target="exceptionSlot"]')
    
    if (!slot) return

    if (slot.dataset.businessHoursTarget === "slot") {
      const openingInput = slot.querySelector('input[name*="[opening_time]"]')
      const closingInput = slot.querySelector('input[name*="[closing_time]"]')
      
      if (openingInput && closingInput) {
        if (openingInput.value) {
          closingInput.min = openingInput.value
        }
        if (closingInput.value) {
          openingInput.max = closingInput.value
        }
        
        if (openingInput.value && closingInput.value && openingInput.value >= closingInput.value) {
          closingInput.setCustomValidity("Closing time must be after opening time")
        } else {
          closingInput.setCustomValidity("")
        }
      }
    } else {
      const fromInput = slot.querySelector('input[name*="[close_from]"]')
      const tillInput = slot.querySelector('input[name*="[close_till]"]')
      
      if (fromInput && tillInput) {
        if (fromInput.value) {
          tillInput.min = fromInput.value
        }
        if (tillInput.value) {
          fromInput.max = tillInput.value
        }
        
        if (fromInput.value && tillInput.value && fromInput.value >= tillInput.value) {
          tillInput.setCustomValidity("Close till must be after close from")
        } else {
          tillInput.setCustomValidity("")
        }
      }
    }
  }
}
