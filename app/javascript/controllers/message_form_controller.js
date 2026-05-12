import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "textarea", "emojiPicker", "voiceBtn", "recordingIndicator"]

  initialize() {
    this.selectedFiles = []
    this.emojiPickerOpen = false
    this.isRecording = false
    this.audioChunks = []
    this.emojis = {
      "Smileys": ['😀','😃','😄','😁','😆','😅','🤣','😂','🙂','😊','😇','🥰','😍','😘','😗','😋','😛','😜','🤪','😝','🤑','🤗','🤭','😐','😑','😶','😏','😒','🙄','😬','😮‍💨','🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🥴','😵','🤯','🥳','🥺','😢','😭','😤','😠','😡','🤬','💀','☠️','💩','🤡','👹','👺','👻','👽','👾','🤖'],
      "Gestures": ['👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞','🫰','🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','🫵','👍','👎','✊','👊','🤛','🤜','👏','🙌','🫶','👐','🤲','🤝','🙏','💪','🫂'],
      "Hearts": ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','💟','♥️','🩷','🩵','🩶'],
      "Objects": ['🎉','🎊','🎈','🎁','🏆','🔥','⭐','✨','💫','🌟','💯','💥','🎵','🎶','👑','💎','🔔','📌','🚀','💡','📎','✅','❌','⚡','☀️','🌈','🌸','🍀']
    }
  }

  connect() {
    this.renderEmojis()
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this.boundClear = () => this.clear()
    document.addEventListener("click", this.boundCloseOnOutsideClick)
    document.addEventListener("deskbolic:message-sent", this.boundClear)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
    document.removeEventListener("deskbolic:message-sent", this.boundClear)
    this.stopRecording()
  }

  // --- Emoji Logic ---
  toggleEmojiPicker(event) {
    event.stopPropagation()
    this.emojiPickerOpen = !this.emojiPickerOpen
    this.emojiPickerTarget.style.display = this.emojiPickerOpen ? "block" : "none"
  }

  closeOnOutsideClick(event) {
    if (this.emojiPickerOpen && !this.emojiPickerTarget.contains(event.target) && !event.target.closest("[data-action*='message-form#toggleEmojiPicker']")) {
      this.emojiPickerOpen = false
      this.emojiPickerTarget.style.display = "none"
    }
  }

  renderEmojis() {
    this.emojiPickerTarget.innerHTML = ""
    Object.entries(this.emojis).forEach(([category, list]) => {
      const section = document.createElement("div")
      section.className = "de-emoji-section"
      const heading = document.createElement("div")
      heading.className = "de-emoji-heading"
      heading.textContent = category
      section.appendChild(heading)
      const grid = document.createElement("div")
      grid.className = "de-emoji-grid"
      list.forEach(emoji => {
        const btn = document.createElement("button")
        btn.type = "button"
        btn.className = "de-emoji-item"
        btn.textContent = emoji
        btn.dataset.action = "click->message-form#insertEmoji"
        grid.appendChild(btn)
      })
      section.appendChild(grid)
      this.emojiPickerTarget.appendChild(section)
    })
  }

  insertEmoji(event) {
    const emoji = event.currentTarget.textContent
    const textarea = this.textareaTarget
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    textarea.value = textarea.value.substring(0, start) + emoji + textarea.value.substring(end)
    textarea.selectionStart = textarea.selectionEnd = start + emoji.length
    textarea.focus()
    this.emojiPickerOpen = false
    this.emojiPickerTarget.style.display = "none"
  }

  // --- Voice Logic ---
  async toggleVoiceRecording(event) {
    event.preventDefault()
    if (this.isRecording) {
      this.stopRecording()
    } else {
      await this.startRecording()
    }
  }

  async startRecording() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia || !window.MediaRecorder) {
      this.showError("Voice recording is not supported in this browser")
      return
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.mediaRecorder = new MediaRecorder(stream)
      this.audioChunks = []

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) this.audioChunks.push(event.data)
      }

      this.mediaRecorder.onstop = () => {
        if (!this.audioChunks.length) return

        const type = this.mediaRecorder.mimeType || "audio/webm"
        const extension = type.includes("mp4") ? "m4a" : "webm"
        const audioBlob = new Blob(this.audioChunks, { type })
        const file = new File([audioBlob], `voice-message-${Date.now()}.${extension}`, { type })
        this.addFile(file)
        
        // Stop all tracks
        stream.getTracks().forEach(track => track.stop())
      }

      this.mediaRecorder.start()
      this.isRecording = true
      this.updateVoiceUI(true)
    } catch (err) {
      console.error("Error accessing microphone:", err)
      this.showError("Microphone permission is required to record voice")
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.isRecording) {
      this.mediaRecorder.stop()
      this.isRecording = false
      this.updateVoiceUI(false)
    }
  }

  updateVoiceUI(recording) {
    if (this.hasVoiceBtnTarget) {
      this.voiceBtnTarget.classList.toggle("recording", recording)
      this.voiceBtnTarget.title = recording ? "Stop recording" : "Record voice"
    }
    if (this.hasRecordingIndicatorTarget) {
      this.recordingIndicatorTarget.style.display = recording ? "flex" : "none"
    }
  }

  // --- File Logic ---
  openFilePicker(event) {
    event.preventDefault()
    this.inputTarget.click()
  }

  previewFiles() {
    if (this.inputTarget.files && this.inputTarget.files.length > 0) {
      const newFiles = Array.from(this.inputTarget.files)
      this.selectedFiles = [...this.selectedFiles, ...newFiles]
      this.syncInput()
      this.renderPreviews()
    }
  }

  addFile(file) {
    this.selectedFiles.push(file)
    this.syncInput()
    this.renderPreviews()
  }

  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.selectedFiles.splice(index, 1)
    this.syncInput()
    this.renderPreviews()
  }

  syncInput() {
    const dataTransfer = new DataTransfer()
    this.selectedFiles.forEach(file => dataTransfer.items.add(file))
    this.inputTarget.files = dataTransfer.files
  }

  renderPreviews() {
    this.previewTarget.innerHTML = ""
    this.previewTarget.classList.toggle("visible", this.selectedFiles.length > 0)

    this.selectedFiles.forEach((file, index) => {
      const chip = document.createElement("div")
      chip.className = "de-file-chip"
      const thumb = document.createElement("div")
      thumb.className = "de-file-thumb"
      
      if (file.type.startsWith("image/")) {
        const reader = new FileReader()
        reader.onload = (e) => { thumb.innerHTML = `<img src="${e.target.result}" />` }
        reader.readAsDataURL(file)
      } else if (file.type.startsWith("video/")) {
        thumb.innerHTML = "🎬"
      } else if (file.type.startsWith("audio/")) {
        thumb.innerHTML = "🎤"
      } else {
        thumb.innerHTML = "📄"
      }
      
      chip.appendChild(thumb)
      const name = document.createElement("span")
      name.className = "de-file-name"
      name.title = file.name
      name.textContent = file.name
      chip.appendChild(name)
      const removeBtn = document.createElement("span")
      removeBtn.className = "de-file-remove"
      removeBtn.innerHTML = "&times;"
      removeBtn.dataset.index = index
      removeBtn.dataset.action = "click->message-form#removeFile"
      chip.appendChild(removeBtn)
      this.previewTarget.appendChild(chip)
    })
  }

  showError(message) {
    this.previewTarget.innerHTML = ""
    this.previewTarget.classList.add("visible")

    const error = document.createElement("div")
    error.className = "composer-error"
    error.textContent = message
    this.previewTarget.appendChild(error)

    clearTimeout(this.errorTimer)
    this.errorTimer = setTimeout(() => {
      if (this.previewTarget.contains(error)) {
        this.previewTarget.innerHTML = ""
        this.previewTarget.classList.remove("visible")
      }
    }, 4000)
  }

  clear() {
    this.selectedFiles = []
    if (this.hasInputTarget) this.inputTarget.value = ""
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = ""
      this.previewTarget.classList.remove("visible")
    }
    if (this.hasTextareaTarget) this.textareaTarget.value = ""
    this.stopRecording()
  }
}
