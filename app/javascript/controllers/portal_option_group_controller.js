import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "option",
    "uploadBox",
    "fileInput",
    "uploadTitle",
    "progress",
    "progressFill",
    "progressLabel"
  ]

  connect() {
    this.sync()
  }

  sync() {
    this.optionTargets.forEach((option) => {
      option.classList.toggle("is-selected", this.getInput(option)?.checked)
    })
    this.syncUploadBox()
  }

  select(event) {
    event.preventDefault()

    const input = this.getInput(event.currentTarget)
    if (!input || input.disabled) return

    input.checked = input.type === "checkbox" ? !input.checked : true
    input.dispatchEvent(new Event("change", { bubbles: true }))
    this.sync()
  }

  openUploadPicker(event) {
    if (event.target === this.fileInputTarget) return
    event.preventDefault()
    event.stopPropagation()
    if (event.type === "keydown" && !["Enter", " "].includes(event.key)) return
    this.fileInputTarget.click()
  }

  uploadFile(event) {
    event.stopPropagation()
    const file = this.fileInputTarget.files?.[0]
    if (!file) return

    this.uploadTitleTarget.textContent = file.name
    this.showProgress()

    window.requestAnimationFrame(() => {
      this.progressFillTarget.style.width = "100%"
    })

    window.setTimeout(() => {
      this.progressLabelTarget.textContent = "Upload complete"
    }, 500)

    window.setTimeout(() => {
      this.hideProgress()
    }, 900)
  }

  clearUpload(event) {
    event.preventDefault()
    event.stopPropagation()
    this.fileInputTarget.value = ""
    this.uploadTitleTarget.textContent = "Upload hero image"
    this.progressFillTarget.style.width = "0%"
    this.hideProgress()
  }

  getInput(option) {
    return option.querySelector("input")
  }

  showProgress() {
    this.progressFillTarget.style.width = "0%"
    this.progressLabelTarget.textContent = "Uploading, wait..."
    this.progressTarget.classList.remove("is-hidden")
  }

  hideProgress() {
    this.progressTarget.classList.add("is-hidden")
  }

  syncUploadBox() {
    if (!this.hasUploadBoxTarget) return

    const isImageSelected = this.optionTargets.some((option) => {
      const input = this.getInput(option)
      return input?.checked && input.value === "image"
    })

    this.uploadBoxTarget.classList.toggle("is-hidden", !isImageSelected)
  }
}