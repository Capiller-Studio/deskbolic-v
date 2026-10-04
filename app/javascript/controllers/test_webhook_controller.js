import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    outgoingUrl: String,
    incomingUrl: String
  }
  
  static targets = [
    "outboundBtn", "outboundResult", "outboundStatus", "outboundBody",
    "inboundBtn", "inboundInput", "inboundResult", "inboundMapped"
  ]

  fireOutbound(event) {
    event.preventDefault()
    
    const originalText = this.outboundBtnTarget.innerText
    this.outboundBtnTarget.innerText = "Firing..."
    this.outboundBtnTarget.disabled = true
    
    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""

    fetch(this.outgoingUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      }
    })
    .then(response => response.json().then(data => ({ status: response.status, body: data })))
    .catch(error => ({ status: 500, error: error.message }))
    .then(data => {
      this.showOutboundResult(data)
    })
    .finally(() => {
      this.outboundBtnTarget.innerText = originalText
      this.outboundBtnTarget.disabled = false
    })
  }

  showOutboundResult(data) {
    this.outboundResultTarget.style.display = "block"
    
    let statusText = "ERROR"
    let statusColor = "#ef4444"
    let statusBg = "#fef2f2"
    
    if (data.status >= 200 && data.status < 300) {
      statusText = `${data.status} SUCCESS`
      statusColor = "#16a34a"
      statusBg = "#f0fdf4"
    } else if (data.status) {
      statusText = `${data.status} FAILED`
      statusColor = "#ca8a04"
      statusBg = "#fefce8"
    }
    
    this.outboundStatusTarget.innerText = statusText
    this.outboundStatusTarget.style.color = statusColor
    this.outboundStatusTarget.style.backgroundColor = statusBg
    
    const body = data.body || data.error || JSON.stringify(data)
    this.outboundBodyTarget.innerText = typeof body === "object" ? JSON.stringify(body, null, 2) : body
  }

  testInbound(event) {
    event.preventDefault()
    
    const payloadText = this.inboundInputTarget.value
    if (!payloadText.trim()) {
      alert("Please enter a JSON payload to test.")
      return
    }
    
    const originalText = this.inboundBtnTarget.innerText
    this.inboundBtnTarget.innerText = "Testing..."
    this.inboundBtnTarget.disabled = true
    
    const formData = new FormData()
    formData.append("payload", payloadText)
    
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""

    fetch(this.incomingUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json"
      },
      body: formData
    })
    .then(response => response.json().then(data => ({ status: response.status, body: data })))
    .catch(error => ({ status: 500, error: error.message }))
    .then(data => {
      this.inboundResultTarget.style.display = "block"
      if (data.status >= 200 && data.status < 300) {
        this.inboundMappedTarget.innerText = JSON.stringify(data.body.mapped_result || data.body, null, 2)
      } else {
        this.inboundMappedTarget.innerText = `Error: ${data.body?.error || data.error || "Invalid request"}`
      }
    })
    .finally(() => {
      this.inboundBtnTarget.innerText = originalText
      this.inboundBtnTarget.disabled = false
    })
  }
}
