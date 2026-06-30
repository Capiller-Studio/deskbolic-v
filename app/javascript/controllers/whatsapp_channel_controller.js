import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    appId: String,
    configId: String,
    callbackUrl: String
  }
  static targets = ["callbackForm", "code"]

  connect() {
    this.loadFacebookSDK()
  }

  loadFacebookSDK() {
    if (window.FB) return

    window.fbAsyncInit = () => {
      window.FB.init({
        appId: this.appIdValue,
        cookie: true,
        xfbml: true,
        version: "v25.0"
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

  connectWa(event) {
    if (event) event.preventDefault()

    if (!window.FB) {
      alert("Facebook SDK is not loaded yet. Please try again in a few seconds.")
      return
    }

    if (!this.configIdValue) {
      alert("WhatsApp Configuration ID is missing. Please contact support.")
      return
    }

    // Launch WhatsApp Embedded Signup Flow
    window.FB.login(
      (response) => {
        if (response.authResponse) {
          // Send the authorization code to our backend callback
          this.codeTarget.value = response.authResponse.code
          this.callbackFormTarget.submit()
        } else {
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
          sessionInfoVersion: "2"
        }
      }
    )
  }
}
