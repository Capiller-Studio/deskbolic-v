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
    document.addEventListener("click", this.boundCloseOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
  }

  // --- Emoji Logic ---
  toggleEmojiPicker(event) {
    event.stopPropagation()
    this.emojiPickerOpen = !this.emojiPickerOpen
    this.emojiPickerTarget.style.display = this.emojiPickerOpen ? "block" : "none"
  }

  closeOnOutsideClick(event) {
    if (this.emojiPickerOpen && !this.emojiPickerTarget.contains(event.target)) {
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
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.mediaRecorder = new MediaRecorder(stream)
      this.audioChunks = []

      this.mediaRecorder.ondataavailable = (event) => {
        this.audioChunks.push(event.data)
      }

      this.mediaRecorder.onstop = () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
        const file = new File([audioBlob], `voice-message-${Date.now()}.webm`, { type: 'audio/webm' })
        this.addFile(file)
        
        // Stop all tracks
        stream.getTracks().forEach(track => track.stop())
      }

      this.mediaRecorder.start()
      this.isRecording = true
      this.updateVoiceUI(true)
    } catch (err) {
      console.error("Error accessing microphone:", err)
      alert("Could not access microphone. Please check permissions.")
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
    }
    if (this.hasRecordingIndicatorTarget) {
      this.recordingIndicatorTarget.style.display = recording ? "flex" : "none"
    }
  }

  // --- File Logic ---
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

  clear() {
    this.selectedFiles = []
    if (this.hasInputTarget) this.inputTarget.value = ""
    if (this.hasPreviewTarget) this.previewTarget.innerHTML = ""
    if (this.hasTextareaTarget) this.textareaTarget.value = ""
    this.stopRecording()
  }
}
