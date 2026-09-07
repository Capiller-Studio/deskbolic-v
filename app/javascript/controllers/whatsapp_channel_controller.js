import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    appId: String,
    configId: String,
    callbackUrl: String
  }
  static targets = ["callbackForm", "code", "wabaId", "phoneNumberId", "connectButton", "buttonSpinner", "buttonText"]

  connect() {
    this.authCode = null
    this.sessionData = null
    this.submissionTimeout = null
    this.isSubmitted = false

    this.boundMessageHandler = this.handleEmbeddedMessage.bind(this)
    window.addEventListener("message", this.boundMessageHandler)
    this.loadFacebookSDK()
  }

  disconnect() {
    this.clearSubmissionTimeout()
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
          this.sessionData = data.data || {}
          if (this.sessionData.waba_id && this.hasWabaIdTarget) {
            this.wabaIdTarget.value = this.sessionData.waba_id
          }
          if (this.sessionData.phone_number_id && this.hasPhoneNumberIdTarget) {
            this.phoneNumberIdTarget.value = this.sessionData.phone_number_id
          }
          this.attemptSubmit()
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

    // Reset latch state for new connection attempt
    this.clearSubmissionTimeout()
    this.authCode = null
    this.sessionData = null
    this.isSubmitted = false

    if (this.hasCodeTarget) this.codeTarget.value = ""
    if (this.hasWabaIdTarget) this.wabaIdTarget.value = ""
    if (this.hasPhoneNumberIdTarget) this.phoneNumberIdTarget.value = ""

    this.setLoadingState()

    // Launch WhatsApp Embedded Signup Flow
    window.FB.login(
      (response) => {
        if (response.authResponse && response.authResponse.code) {
          this.authCode = response.authResponse.code
          if (this.hasCodeTarget) {
            this.codeTarget.value = this.authCode
          }
          this.attemptSubmit()
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

  attemptSubmit() {
    if (this.isSubmitted) return

    // Case 1: Both FB.login auth code and sessionInfo (waba_id / phone_number_id) received.
    // Submit immediately!
    if (this.authCode && this.sessionData) {
      this.clearSubmissionTimeout()
      this.isSubmitted = true
      this.callbackFormTarget.submit()
      return
    }

    // Case 2: FB.login returned auth code first, postMessage FINISH hasn't arrived yet.
    // Wait up to 1200ms for postMessage to arrive. If it times out (e.g. browser blocked postMessage),
    // submit with auth code alone and let the backend fallback discover the account details.
    if (this.authCode && !this.sessionData) {
      if (!this.submissionTimeout) {
        this.submissionTimeout = setTimeout(() => {
          if (!this.isSubmitted && this.authCode) {
            this.isSubmitted = true
            this.callbackFormTarget.submit()
          }
        }, 1200)
      }
      return
    }

    // Case 3: FINISH postMessage arrived first, waiting for FB.login popup to close and return auth code.
    // Nothing to do here; FB.login callback will fire momentarily and enter Case 1.
  }

  clearSubmissionTimeout() {
    if (this.submissionTimeout) {
      clearTimeout(this.submissionTimeout)
      this.submissionTimeout = null
    }
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
    this.clearSubmissionTimeout()
    this.authCode = null
    this.sessionData = null
    this.isSubmitted = false

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
