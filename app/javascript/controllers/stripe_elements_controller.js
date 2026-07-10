import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    clientSecret: String,
    publishableKey: String
  }
  static targets = ["element", "error", "form", "submitButton"]

  connect() {
    this.mounted = false
  }

  mount() {
    if (this.mounted) return

    this.loadStripeScript().then(() => {
      if (!this.publishableKeyValue || this.publishableKeyValue === "mock_secret_for_ui_testing") {
        this.errorTarget.textContent = "Stripe is not configured. Please add your API keys."
        return
      }

      this.stripe = window.Stripe(this.publishableKeyValue)
      this.elements = this.stripe.elements()

      this.card = this.elements.create("card", {
        style: {
          base: {
            fontSize: '16px',
            color: '#0f172a',
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
            '::placeholder': {
              color: '#94a3b8',
            },
          },
          invalid: {
            color: '#ef4444',
            iconColor: '#ef4444',
          },
        }
      })
      this.card.mount(this.elementTarget)
      this.mounted = true

      this.card.on("change", (event) => {
        if (event.error) {
          this.errorTarget.textContent = event.error.message
        } else {
          this.errorTarget.textContent = ""
        }
      })
    })
  }

  loadStripeScript() {
    return new Promise((resolve) => {
      if (window.Stripe) return resolve()
      const script = document.createElement("script")
      script.src = "https://js.stripe.com/v3/"
      script.onload = resolve
      document.head.appendChild(script)
    })
  }

  async submit(event) {
    event.preventDefault()

    if (!this.stripe || !this.card) {
      this.errorTarget.textContent = "Card element is not ready. Please try again."
      return
    }

    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Saving..."

    const { setupIntent, error } = await this.stripe.confirmCardSetup(this.clientSecretValue, {
      payment_method: {
        card: this.card
      }
    })

    if (error) {
      this.errorTarget.textContent = error.message
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = "Save Card"
    } else {
      // Create a hidden form that posts to payment_methods#create
      const form = document.createElement("form")
      form.method = "POST"
      form.action = "/payment_methods"

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      if (csrfToken) {
        const csrfInput = document.createElement("input")
        csrfInput.type = "hidden"
        csrfInput.name = "authenticity_token"
        csrfInput.value = csrfToken
        form.appendChild(csrfInput)
      }

      const pmInput = document.createElement("input")
      pmInput.type = "hidden"
      pmInput.name = "payment_method_id"
      pmInput.value = setupIntent.payment_method
      form.appendChild(pmInput)

      document.body.appendChild(form)
      form.submit()
    }
  }
}
