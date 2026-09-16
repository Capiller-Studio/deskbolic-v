import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import FormWizardController from "./controllers/form_wizard_controller"
import RegistrationWizardController from "./controllers/registration_wizard_controller"
import PasswordStrengthController from "./controllers/password_strength_controller"
import SelectController from "./controllers/select_controller"

const application = Application.start()
application.register("form-wizard", FormWizardController)
application.register("registration-wizard", RegistrationWizardController)
application.register("password-strength", PasswordStrengthController)
application.register("select", SelectController)
