import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["richTextContent", "externalUrlField", "value", "input",
    "bannerInput", "bannerPreview", "bannerPreviewImage", "bannerIcon", "bannerTitle", "bannerSubtitle"]

  static values = { existingBannerUrl: String }

  connect() {
    this.toggleType()
    this.showExistingBanner()
  }

  showExistingBanner() {
    if (this.hasExistingBannerUrlValue && this.existingBannerUrlValue) {
      this._setBannerPreview(this.existingBannerUrlValue)
    }
  }

  previewBanner() {
    const file = this.bannerInputTarget.files[0]
    if (!file) return

    const supportedImageTypes = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    if (!supportedImageTypes.includes(file.type)) {
      this.bannerInputTarget.value = ""
      window.alert("Unsupported banner image format. Please upload JPG, PNG, GIF, or WEBP.")
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this._setBannerPreview(e.target.result)
    }
    reader.readAsDataURL(file)
  }

  _setBannerPreview(src) {
    if (this.hasBannerPreviewImageTarget) {
      this.bannerPreviewImageTarget.src = src
    }
    if (this.hasBannerPreviewTarget) {
      this.bannerPreviewTarget.classList.add("hc-file-upload--selected")
    }
    if (this.hasBannerIconTarget) {
      this.bannerIconTarget.style.display = "none"
    }
    if (this.hasBannerTitleTarget) {
      this.bannerTitleTarget.textContent = "Banner selected"
    }
    if (this.hasBannerSubtitleTarget) {
      this.bannerSubtitleTarget.textContent = "Click to change"
    }
  }

  toggleType() {
    const select = this.element.querySelector("[name='article[article_type]']")
    const isExternal = select && select.value === "external_link"

    if (this.hasRichTextContentTarget) {
      this.richTextContentTarget.style.display = isExternal ? "none" : "block"
    }

    if (this.hasExternalUrlFieldTarget) {
      this.externalUrlFieldTarget.style.display = isExternal ? "block" : "none"
    }
  }

  increase() {
    const current = parseInt(this.inputTarget.value) || 0
    this.inputTarget.value = current + 1
    this.valueTarget.textContent = current + 1
  }

  decrease() {
    const current = parseInt(this.inputTarget.value) || 0
    if (current > 0) {
      this.inputTarget.value = current - 1
      this.valueTarget.textContent = current - 1
    }
  }
}