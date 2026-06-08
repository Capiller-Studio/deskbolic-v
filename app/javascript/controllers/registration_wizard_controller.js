import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "progressBar", "progressText", "progressFill", "firstNameInput", "lastNameInput", "countryInput", "emailInput", "emailError"]

  connect() {
    this.currentStep = 0
    this.showCurrentStep()
  }

  showCurrentStep() {
    this.stepTargets.forEach((el, index) => {
      if (index === this.currentStep) {
        el.classList.remove("hidden")
      } else {
        el.classList.add("hidden")
      }
    })
  }

  async nextStep(event) {
    if (event) event.preventDefault()
    
    // If we are moving from Step 1 to Step 2, validate inputs
    if (this.currentStep === 0) {
      if (this.hasFirstNameInputTarget && !this.firstNameInputTarget.reportValidity()) return
      if (this.hasLastNameInputTarget && !this.lastNameInputTarget.reportValidity()) return
      if (this.hasCountryInputTarget && !this.countryInputTarget.reportValidity()) return
      if (this.hasEmailInputTarget && !this.emailInputTarget.reportValidity()) return

      const email = this.emailInputTarget.value
      if (!email) {
        this.emailErrorTarget.textContent = "Email is required"
        this.emailErrorTarget.classList.remove("hidden")
        return
      }
      
      const response = await fetch(`/users/check_email?email=${encodeURIComponent(email)}`)
      const data = await response.json()
      
      if (data.exists) {
        this.emailErrorTarget.textContent = "Email already exists. Please log in."
        this.emailErrorTarget.classList.remove("hidden")
        return
      }
      this.emailErrorTarget.classList.add("hidden")
    }

    if (this.currentStep < this.stepTargets.length - 1) {
      this.currentStep++
      this.showCurrentStep()
    }
  }

  prevStep(event) {
    if (event) event.preventDefault()
    
    if (this.currentStep > 0) {
      this.currentStep--
      this.showCurrentStep()
    }
  }

  submitForm(event) {
    // When final submit is clicked, show progress bar and hide the form
    this.stepTargets.forEach(el => el.classList.add("hidden"))
    this.progressBarTarget.classList.remove("hidden")
    
    // Simulate progress bar filling up to 90% while the server processes
    let progress = 0
    this.progressInterval = setInterval(() => {
      progress += Math.random() * 10
      if (progress > 90) progress = 90
      
      this.progressFillTarget.style.width = `${progress}%`
      this.progressTextTarget.textContent = `Setting up your account... ${Math.round(progress)}%`
      
      if (progress === 90) clearInterval(this.progressInterval)
    }, 500)
  }

  handleSubmitEnd(event) {
    if (event.detail.success) {
      clearInterval(this.progressInterval)
      if (this.hasProgressFillTarget) this.progressFillTarget.style.width = "100%"
      if (this.hasProgressTextTarget) this.progressTextTarget.textContent = "Account created successfully!"
    } else {
      // If the form submission failed (e.g. validation errors returning 422 Unprocessable Entity)
      clearInterval(this.progressInterval)
      this.progressBarTarget.classList.add("hidden")
      // Show the last step again so they can fix errors
      this.currentStep = this.stepTargets.length - 1
      this.showCurrentStep()
      this.progressFillTarget.style.width = "0%"
    }
  }
}
