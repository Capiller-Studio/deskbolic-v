import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import RegistrationWizardController from "./controllers/registration_wizard_controller"
import PasswordStrengthController from "./controllers/password_strength_controller"

const application = Application.start()
application.register("registration-wizard", RegistrationWizardController)
application.register("password-strength", PasswordStrengthController)
