import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    appId: String,
    configId: String,
    callbackUrl: String
  }
  static targets = ["callbackForm", "code", "wabaId", "phoneNumberId", "connectButton", "buttonSpinner", "buttonText"]

  connect() {
    this.boundMessageHandler = this.handleEmbeddedMessage.bind(this)
    window.addEventListener("message", this.boundMessageHandler)
    this.loadFacebookSDK()
  }

  disconnect() {
    if (this.boundMessageHandler) {
      window.removeEventListener("message", this.boundMessageHandler)
    }
  }

  loadFacebookSDK() {
    if (window.FB) return

    window.fbAsyncInit = () => {
      window.FB.init({
        appId: this.appIdValue,
        cookie: true,
        xfbml: true,
        version: "v26.0"
      })
    }

    ;(function (d, s, id) {
      var js,
        fjs = d.getElementsByTagName(s)[0]
      if (d.getElementById(id)) {
        return
      }
      js = d.createElement(s)
      js.id = id
      js.src = "https://connect.facebook.net/en_US/sdk.js"
      fjs.parentNode.insertBefore(js, fjs)
    })(document, "script", "facebook-jssdk")
  }

  handleEmbeddedMessage(event) {
    if (event.origin !== "https://www.facebook.com" && event.origin !== "https://web.facebook.com") return

    try {
      const data = typeof event.data === "string" ? JSON.parse(event.data) : event.data
      if (data && data.type === "WA_EMBEDDED_SIGNUP") {
        if (data.event === "FINISH") {
          const sessionData = data.data || {}
          if (sessionData.waba_id && this.hasWabaIdTarget) {
            this.wabaIdTarget.value = sessionData.waba_id
          }
          if (sessionData.phone_number_id && this.hasPhoneNumberIdTarget) {
            this.phoneNumberIdTarget.value = sessionData.phone_number_id
          }
        } else if (data.event === "CANCEL") {
          this.resetButtonState()
        } else if (data.event === "ERROR") {
          this.resetButtonState()
          console.error("WhatsApp Embedded Signup error:", data.data)
        }
      }
    } catch (e) {
      // Ignore non-JSON postMessages
    }
  }

  connectWa(event) {
    if (event) event.preventDefault()

    if (!window.FB) {
      alert("Facebook SDK is loading. Please try again in a moment.")
      return
    }

    if (!this.configIdValue) {
      alert("WhatsApp Configuration ID is missing. Please check your credentials configuration.")
      return
    }

    this.setLoadingState()

    // Launch WhatsApp Embedded Signup Flow
    window.FB.login(
      (response) => {
        if (response.authResponse && response.authResponse.code) {
          // Send the authorization code to our backend callback
          this.codeTarget.value = response.authResponse.code
          this.callbackFormTarget.submit()
        } else {
          this.resetButtonState()
          console.log("User cancelled login or did not fully authorize.")
        }
      },
      {
        config_id: this.configIdValue,
        response_type: "code",
        override_default_response_type: true,
        extras: {
          setup: {},
          featureType: "",
          sessionInfoVersion: "3"
        }
      }
    )
  }

  setLoadingState() {
    if (this.hasConnectButtonTarget) {
      this.connectButtonTarget.disabled = true
      this.connectButtonTarget.classList.add("is-loading")
    }
    if (this.hasButtonSpinnerTarget) {
      this.buttonSpinnerTarget.style.display = "inline-block"
    }
    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.textContent = "Connecting..."
    }
  }

  resetButtonState() {
    if (this.hasConnectButtonTarget) {
      this.connectButtonTarget.disabled = false
      this.connectButtonTarget.classList.remove("is-loading")
    }
    if (this.hasButtonSpinnerTarget) {
      this.buttonSpinnerTarget.style.display = "none"
    }
    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.textContent = "Connect with WhatsApp"
    }
  }
}
