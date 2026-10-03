import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step", "progressBar", "progressText", "progressFill",
    "firstNameInput", "lastNameInput", "countryInput", "emailInput", "emailError",
    "workspaceInput", "workspaceError",
    "identifierInput", "identifierError"
  ]

  connect() {
    this.currentStep = 0
    this.identifierManuallyEdited = false
    this.submitting = false
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

      const email = this.emailInputTarget.value.trim()
      if (!email) {
        this.emailErrorTarget.textContent = "Email is required"
        this.emailErrorTarget.classList.remove("hidden")
        return
      }

      try {
        const response = await fetch(`/auth/check_email?email=${encodeURIComponent(email)}`)
        const data = await response.json()

        if (data.exists) {
          this.emailErrorTarget.textContent = "Email already exists. Please log in."
          this.emailErrorTarget.classList.remove("hidden")
          return
        }
      } catch (err) {
        console.error("Error checking email:", err)
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

  slugify(text) {
    return text
      .toString()
      .toLowerCase()
      .trim()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
  }

  handleWorkspaceNameInput() {
    this.clearWorkspaceError()

    if (!this.identifierManuallyEdited && this.hasIdentifierInputTarget && this.hasWorkspaceInputTarget) {
      const name = this.workspaceInputTarget.value
      this.identifierInputTarget.value = this.slugify(name)
      this.clearIdentifierError()
    }
  }

  handleIdentifierInput() {
    if (this.hasIdentifierInputTarget && this.identifierInputTarget.value.trim() === "") {
      this.identifierManuallyEdited = false
    } else {
      this.identifierManuallyEdited = true
    }
    this.clearIdentifierError()
  }

  validateWorkspace() {
    if (!this.hasWorkspaceInputTarget) return true

    const name = this.workspaceInputTarget.value.trim()
    if (!name) {
      this.showWorkspaceError("Workspace name is required")
      return false
    }

    this.clearWorkspaceError()
    return true
  }

  async validateIdentifier() {
    if (!this.hasIdentifierInputTarget) return true

    const rawIdentifier = this.identifierInputTarget.value.trim()
    // Blank identifier is permitted as backend auto-generates it from workspace name
    if (!rawIdentifier) {
      this.clearIdentifierError()
      return true
    }

    const slug = this.slugify(rawIdentifier)
    if (slug.length < 3) {
      this.showIdentifierError("Workspace identifier must be at least 3 characters")
      return false
    }
    if (slug.length > 63) {
      this.showIdentifierError("Workspace identifier cannot exceed 63 characters")
      return false
    }

    try {
      const response = await fetch(`/auth/check_identifier?identifier=${encodeURIComponent(slug)}`)
      const data = await response.json()

      if (!data.valid) {
        this.showIdentifierError(data.error)
        return false
      }
      this.clearIdentifierError()
      return true
    } catch (e) {
      console.error("Error validating identifier:", e)
      return true
    }
  }

  showWorkspaceError(msg) {
    if (this.hasWorkspaceErrorTarget) {
      this.workspaceErrorTarget.textContent = msg
      this.workspaceErrorTarget.classList.remove("hidden")
    }
    if (this.hasWorkspaceInputTarget) {
      this.workspaceInputTarget.classList.add("is-invalid")
    }
  }

  clearWorkspaceError() {
    if (this.hasWorkspaceErrorTarget) {
      this.workspaceErrorTarget.textContent = ""
      this.workspaceErrorTarget.classList.add("hidden")
    }
    if (this.hasWorkspaceInputTarget) {
      this.workspaceInputTarget.classList.remove("is-invalid")
    }
  }

  showIdentifierError(msg) {
    if (this.hasIdentifierErrorTarget) {
      this.identifierErrorTarget.textContent = msg
      this.identifierErrorTarget.classList.remove("hidden")
    }
    if (this.hasIdentifierInputTarget) {
      this.identifierInputTarget.classList.add("is-invalid")
    }
  }

  clearIdentifierError() {
    if (this.hasIdentifierErrorTarget) {
      this.identifierErrorTarget.textContent = ""
      this.identifierErrorTarget.classList.add("hidden")
    }
    if (this.hasIdentifierInputTarget) {
      this.identifierInputTarget.classList.remove("is-invalid")
    }
  }

  async submitForm(event) {
    if (this.submitting) return

    if (event) event.preventDefault()

    const isWorkspaceValid = this.validateWorkspace()
    const isIdentifierValid = await this.validateIdentifier()

    if (!isWorkspaceValid || !isIdentifierValid) {
      return
    }

    this.submitting = true

    // When final submit is clicked, show progress bar and hide the form
    this.stepTargets.forEach(el => el.classList.add("hidden"))
    if (this.hasProgressBarTarget) this.progressBarTarget.classList.remove("hidden")

    // Simulate progress bar filling up to 90% while the server processes
    let progress = 0
    this.progressInterval = setInterval(() => {
      progress += Math.random() * 10
      if (progress > 90) progress = 90

      if (this.hasProgressFillTarget) this.progressFillTarget.style.width = `${progress}%`
      if (this.hasProgressTextTarget) this.progressTextTarget.textContent = `Setting up your account... ${Math.round(progress)}%`

      if (progress === 90) clearInterval(this.progressInterval)
    }, 500)

    this.element.requestSubmit()
  }

  handleSubmitEnd(event) {
    this.submitting = false
    clearInterval(this.progressInterval)

    // Check if errors container exists and has errors rendered
    const errorsContainer = document.getElementById("registration-form-errors")
    const hasErrors = errorsContainer && errorsContainer.children.length > 0 && errorsContainer.textContent.trim().length > 0

    if (event.detail.success && !hasErrors) {
      if (this.hasProgressFillTarget) this.progressFillTarget.style.width = "100%"
      if (this.hasProgressTextTarget) this.progressTextTarget.textContent = "Account created successfully!"
    } else {
      // If the form submission failed or errors were rendered
      if (this.hasProgressBarTarget) this.progressBarTarget.classList.add("hidden")
      // Show the last step again so they can fix errors
      this.currentStep = this.stepTargets.length - 1
      this.showCurrentStep()
      if (this.hasProgressFillTarget) this.progressFillTarget.style.width = "0%"
    }
  }
}
