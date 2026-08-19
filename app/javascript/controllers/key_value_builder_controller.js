import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "testResult", "valueInput"]
  static values = {
    testUrl: String
  }

  connect() {
    this.lastFocusedInput = null
  }

  setFocus(event) {
    this.lastFocusedInput = event.currentTarget
  }

  preventFocus(event) {
    event.preventDefault()
  }

  insertVariable(event) {
    const variable = event.currentTarget.dataset.variable
    if (!variable || !this.lastFocusedInput) return

    const input = this.lastFocusedInput
    const startPos = input.selectionStart
    const endPos = input.selectionEnd

    input.value = input.value.substring(0, startPos) + variable + input.value.substring(endPos, input.value.length)
    
    // Set cursor position after inserted variable
    const newPos = startPos + variable.length
    input.setSelectionRange(newPos, newPos)
    input.focus()
  }

  addRow(event) {
    event.preventDefault()
    
    // Support multiple sections by checking if the button is within a specific section wrapper
    const wrapper = event.currentTarget.closest('[data-key-value-builder-section]') || event.currentTarget.closest('.ui-section') || event.currentTarget.closest('.ui-form-group') || event.currentTarget.closest('.ap-section')
    if (!wrapper) return
    
    const template = wrapper.querySelector('template')
    const container = wrapper.querySelector('.ui-kv-builder') || wrapper.querySelector('.ap-kv-builder') || wrapper.querySelector('.is-kv-table-body')
    
    if (template && container) {
      const content = template.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
      container.insertAdjacentHTML('beforeend', content)
      wrapper.querySelector('.is-kv-table')?.classList.remove('is-kv-table--hidden')
      wrapper.querySelector('.is-kv-empty')?.classList.add('is-kv-empty--hidden')
    }
  }

  removeRow(event) {
    event.preventDefault()
    const row = event.currentTarget.closest('.kv-row') || event.currentTarget.closest('.is-kv-row')
    const wrapper = event.currentTarget.closest('[data-key-value-builder-section]') || event.currentTarget.closest('.ui-section') || event.currentTarget.closest('.ui-form-group') || event.currentTarget.closest('.ap-section')
    row?.remove()

    if (wrapper && !wrapper.querySelector('.is-kv-row')) {
      wrapper.querySelector('.is-kv-table')?.classList.add('is-kv-table--hidden')
      wrapper.querySelector('.is-kv-empty')?.classList.remove('is-kv-empty--hidden')
    }
  }

  async testRun(event) {
    event.preventDefault()
    if (!this.hasTestUrlValue) return

    const form = this.element.closest('form')
    const formData = new FormData(form)
    formData.delete('_method')

    try {
      const response = await fetch(this.testUrlValue, {
        method: "POST",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })
      
      const data = await response.json()
      
      if (this.hasTestResultTarget) {
        this.testResultTarget.style.display = 'block'
        if (data.success) {
          let html = `<div style="display: flex; gap: 20px; flex-wrap: wrap;">`;
          if (data.mapped_data && Object.keys(data.mapped_data).length > 0) {
            html += `<div style="flex: 1; min-width: 250px;">
              <h4 class="f-semi-13" style="margin-bottom: 8px; color: #334155;">Mapped Fields</h4>
              <pre class="f-reg-12" style="background:#e0f2fe; color: #0284c7; padding:10px; border-radius:4px; margin: 0;">${JSON.stringify(data.mapped_data, null, 2)}</pre>
            </div>`;
          }
          html += `<div style="flex: 1; min-width: 250px;">
            <h4 class="f-semi-13" style="margin-bottom: 8px; color: #334155;">Raw Response</h4>
            <pre class="f-reg-12" style="background:#f4f4f5; padding:10px; border-radius:4px; margin: 0; max-height: 400px; overflow-y: auto;">${JSON.stringify(data.payload, null, 2)}</pre>
          </div></div>`;
          
          this.testResultTarget.innerHTML = html
        } else {
          this.testResultTarget.innerHTML = `<div style="color:red;">Error: ${data.error}</div>`
        }
      }
    } catch (error) {
      if (this.hasTestResultTarget) {
        this.testResultTarget.style.display = 'block'
        this.testResultTarget.innerHTML = `<div style="color:red;">Request failed: ${error.message}</div>`
      }
    }
  }
}
