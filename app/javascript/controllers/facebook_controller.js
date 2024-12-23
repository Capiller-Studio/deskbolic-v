import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.loadFacebookSDK();
  }

  loadFacebookSDK() {
    if (document.getElementById('facebook-jssdk')) return;

    const script = document.createElement('script');
    script.id = 'facebook-jssdk';
    script.src = "https://connect.facebook.net/en_US/sdk.js";
    script.async = true;
    script.onload = () => {
      window.fbAsyncInit = () => {
        console.log("Facebook SDK loaded, waiting for app initialization.");
      };
    };
    document.body.appendChild(script);
  }

  fb_login() {
    const appIdInput = document.querySelector('input[name="app_id"]').value.trim();
    if (!appIdInput) {
      console.error("App ID is required for Facebook login.");
      alert("Please enter a valid App ID.");
      return;
    }

    this.initializeFacebook(appIdInput);
    FB.login(response => {
      console.log(response);
      if (response.authResponse) {
        const data = { accessToken: response.authResponse.accessToken };

        fetch('/facebook_page', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          },
          body: JSON.stringify(data)
        }).then((response) => response.text()).
          then((html) => {
            Turbo.renderStreamMessage(html);
          })
      } else if (response.status === 'not_authorized') {
        console.log('User did not fully authorize.');
      } else {
        console.log('User cancelled login or did not fully authorize.');
      }
    }, { scope: 'public_profile,email' });
  }

  fb_logout() {
    FB.logout(response => {
    
    });
  }

  initializeFacebook(appId) {
    if (!FB) {
      console.error("Facebook SDK is not loaded yet.");
      return;
    }
    FB.init({
      appId: appId,
      xfbml: true,
      version: 'v19.0'
    });
  }
}