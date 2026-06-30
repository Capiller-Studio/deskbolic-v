import { Controller } from "@hotwired/stimulus"

// Minimal Stimulus controller for Instagram Channel.
// The Instagram OAuth flow is server-side (redirect-based), so no SDK loading needed.
// This controller handles minor UI interactions on the edit/index pages.
export default class extends Controller {
  connect() {
    // No SDK to load — Instagram uses server-side OAuth redirect
  }
}
