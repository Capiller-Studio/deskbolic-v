import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    publicKey: String,
    intentSecret: String
  }
  static targets = ["cardElement", "error", "form", "submitButton"]

  connect() {
    this.loadStripeScript().then(() => {
      this.stripe = window.Stripe(this.publicKeyValue)
      this.elements = this.stripe.elements()
      
      this.card = this.elements.create("card", {
        style: {
          base: {
            fontSize: '16px',
            color: '#32325d',
            '::placeholder': {
              color: '#aab7c4',
            },
          },
          invalid: {
            color: '#fa755a',
            iconColor: '#fa755a',
          },
        }
      })
      this.card.mount(this.cardElementTarget)
      
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
    this.submitButtonTarget.disabled = true

    const { setupIntent, error } = await this.stripe.confirmCardSetup(this.intentSecretValue, {
      payment_method: {
        card: this.card
      }
    })

    if (error) {
      this.errorTarget.textContent = error.message
      this.submitButtonTarget.disabled = false
    } else {
      const hiddenInput = document.createElement("input")
      hiddenInput.setAttribute("type", "hidden")
      hiddenInput.setAttribute("name", "payment_method_id")
      hiddenInput.setAttribute("value", setupIntent.payment_method)
      this.formTarget.appendChild(hiddenInput)
      this.formTarget.submit()
    }
  }
}
