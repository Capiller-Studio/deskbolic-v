import { Controller } from "@hotwired/stimulus"

// Manages the Facebook Page channel creation flow:
// 1. Loads the Facebook JS SDK
// 2. Opens the FB Login dialog with required permissions
// 3. Sends the short-lived token to the server for exchange
// 4. Handles page selection from the returned page list
export default class extends Controller {
  static values = {
    appId: String,
    callbackUrl: String
  }

  static targets = [
    "step1", "step2", "step3",
    "accessToken", "userAccessToken", "pageIdentifier", "avatarUrl", "channelName"
  ]

  connect() {
    this.loadFacebookSDK()
  }

  // Load the Facebook JS SDK asynchronously
  loadFacebookSDK() {
    if (document.getElementById("facebook-jssdk")) return

    window.fbAsyncInit = () => {
      FB.init({
        appId: this.appIdValue,
        cookie: true,
        xfbml: false,
        version: "v25.0"
      })
    }

    const script = document.createElement("script")
    script.id = "facebook-jssdk"
    script.src = "https://connect.facebook.net/en_US/sdk.js"
    script.async = true
    script.defer = true
    document.head.appendChild(script)
  }

  // Opens the Facebook Login dialog
  connect_fb() {
    if (typeof FB === "undefined") {
      console.error("Facebook SDK not loaded yet")
      return
    }

    FB.login((response) => {
      if (response.authResponse) {
        this.exchangeToken(response.authResponse.accessToken)
      }
    }, {
      scope: [
        "pages_show_list",
        "pages_messaging",
        "pages_manage_metadata",
        "pages_read_engagement"
      ].join(","),
      return_scopes: true
    })
  }



  // Called when "Connect with Facebook" button is clicked
  connectFb(event) {
    event.preventDefault()

    if (typeof FB === "undefined") {
      console.error("Facebook SDK not loaded yet")
      return
    }

    FB.login((response) => {
      if (response.authResponse) {
        this.exchangeToken(response.authResponse.accessToken)
      }
    }, {
      scope: [
        "pages_show_list",
        "pages_messaging",
        "pages_manage_metadata",
        "pages_read_engagement"
      ].join(","),
      return_scopes: true
    })
  }

  // Send the short-lived token to our backend for exchange
  async exchangeToken(accessToken) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    try {
      const response = await fetch(this.callbackUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: new URLSearchParams({ access_token: accessToken })
      })

      if (response.ok) {
        const html = await response.text()
        // Turbo Stream will handle the DOM update automatically
        Turbo.renderStreamMessage(html)
      } else {
        console.error("Token exchange failed:", response.status)
      }
    } catch (error) {
      console.error("Token exchange error:", error)
    }
  }

  // Called when a page card is clicked
  selectPage(event) {
    const card = event.currentTarget
    const pageId = card.dataset.pageId
    const pageName = card.dataset.pageName
    const pageToken = card.dataset.pageToken
    const pageAvatar = card.dataset.pageAvatar
    const userToken = card.dataset.userToken

    // Remove selection from all cards
    document.querySelectorAll(".channel-page-card").forEach(c => {
      c.classList.remove("channel-page-card--selected")
    })

    // Select this card
    card.classList.add("channel-page-card--selected")

    // Fill the hidden form fields
    if (this.hasAccessTokenTarget) this.accessTokenTarget.value = pageToken
    if (this.hasUserAccessTokenTarget) this.userAccessTokenTarget.value = userToken
    if (this.hasPageIdentifierTarget) this.pageIdentifierTarget.value = pageId
    if (this.hasAvatarUrlTarget) this.avatarUrlTarget.value = pageAvatar || ""
    if (this.hasChannelNameTarget) this.channelNameTarget.value = pageName

    // Show step 3
    if (this.hasStep3Target) {
      this.step3Target.classList.remove("channel-step-hidden")
      this.step3Target.scrollIntoView({ behavior: "smooth", block: "center" })
    }
  }
}
