import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.checkSubscription()
  }

  async checkSubscription() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      this.element.style.display = "none"
      return
    }

    try {
      const registration = await navigator.serviceWorker.register("/serviceworker.js")
      const subscription = await registration.pushManager.getSubscription()
      
      this.updateButtonState(!!subscription)
    } catch (e) {
      console.error("ServiceWorker registration failed:", e)
    }
  }

  async toggle(event) {
    event.preventDefault()

    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      alert("Push notifications are not supported by this browser.")
      return
    }

    try {
      this.element.disabled = true
      this.element.textContent = "Processing..."
      
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        await this.unsubscribe(subscription)
      } else {
        await this.subscribe(registration)
      }
    } catch (e) {
      console.error("Toggle failed:", e)
      alert("An error occurred: " + e.message)
    } finally {
      this.element.disabled = false
    }
  }

  async subscribe(registration) {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") {
      alert("Permission for notifications was denied")
      this.updateButtonState(false)
      return
    }

    const vapidPublicKey = this.element.dataset.vapidPublicKey

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey)
    })

    const subscriptionData = subscription.toJSON()
    
    const response = await fetch("/settings/notification_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        subscription: {
          endpoint: subscriptionData.endpoint,
          p256dh: subscriptionData.keys.p256dh,
          auth: subscriptionData.keys.auth
        }
      })
    })

    if (response.ok) {
      this.updateButtonState(true)
    } else {
      alert("Failed to save subscription to server.")
      await subscription.unsubscribe()
      this.updateButtonState(false)
    }
  }

  async unsubscribe(subscription) {
    const endpoint = subscription.endpoint
    
    // Unsubscribe from the browser
    await subscription.unsubscribe()
    
    // Delete from the backend
    const response = await fetch("/settings/notification_subscriptions/dummy", {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ endpoint: endpoint })
    })

    if (!response.ok && response.status !== 404) {
      console.error("Failed to delete subscription on server")
    }

    this.updateButtonState(false)
  }

  updateButtonState(isSubscribed) {
    if (isSubscribed) {
      this.element.textContent = "Disable Browser Notifications"
      this.element.style.background = "#ef4444"
      this.element.style.borderColor = "#ef4444"
      this.element.style.color = "white"
    } else {
      this.element.textContent = "Enable Browser Notifications"
      this.element.style.background = ""
      this.element.style.borderColor = ""
      this.element.style.color = ""
    }
  }

  // Utility to convert Base64 VAPID key to Uint8Array
  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/\-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
