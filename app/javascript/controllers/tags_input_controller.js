import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hiddenInput", "input", "tagsContainer"]

  connect() {
    this.tags = []
    if (this.hiddenInputTarget.value) {
      this.tags = this.hiddenInputTarget.value.split(',').map(t => t.trim()).filter(t => t.length > 0)
    }
    this.renderTags()
  }

  handleKeydown(e) {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault()
      this.addTag()
    } else if (e.key === 'Backspace' && this.inputTarget.value === '') {
      this.removeLastTag()
    }
  }

  addTag() {
    const value = this.inputTarget.value.trim().replace(/,/g, '')
    if (value && !this.tags.includes(value)) {
      this.tags.push(value)
      this.updateHiddenInput()
      this.renderTags()
    }
    this.inputTarget.value = ''
  }

  removeTag(e) {
    e.preventDefault()
    const index = parseInt(e.currentTarget.dataset.index, 10)
    this.tags.splice(index, 1)
    this.updateHiddenInput()
    this.renderTags()
  }

  removeLastTag() {
    if (this.tags.length > 0) {
      this.tags.pop()
      this.updateHiddenInput()
      this.renderTags()
    }
  }

  updateHiddenInput() {
    this.hiddenInputTarget.value = this.tags.join(',')
  }

  renderTags() {
    this.tagsContainerTarget.innerHTML = ''
    this.tags.forEach((tag, index) => {
      const tagEl = document.createElement('span')
      tagEl.className = 'ww-tag'
      tagEl.textContent = tag
      
      const removeBtn = document.createElement('button')
      removeBtn.className = 'ww-tag-remove'
      removeBtn.innerHTML = '&times;'
      removeBtn.type = 'button'
      removeBtn.dataset.index = index
      removeBtn.dataset.action = 'click->tags-input#removeTag'
      
      tagEl.appendChild(removeBtn)
      this.tagsContainerTarget.appendChild(tagEl)
    })
  }

  focusInput() {
    this.inputTarget.focus()
  }
}
