import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    
    fb_login() {
      FB.login(function(response) {
        console.log(response);
        if (response.authResponse) {
          console.log('Logged in.');
          
          // from here i want to pass accessToken to facebook_controller
          console.log(response.authResponse.accessToken);
          const data = { accessToken: response.authResponse.accessToken };
          
          fetch('/facebook_page', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            },
            body: JSON.stringify(data)
          })
          
        } else if (response.status === 'not_authorized') {
          console.log('User did not fully authorize.');
        } else {
          console.log('User cancelled login or did not fully authorize.');
        }
      }, {scope: 'public_profile,email'});
      
      
      
    }
    
    fb_logout() {
      FB.logout(function(response) {
        console.log('Logged out.');
        // You can perform further actions after successful logout here
      });
    }
}