import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import EmailBuilderController from "./page_controllers/email_builder_controller"
import SelectController from "./controllers/select_controller"
import ChoicesController from "./controllers/choices_controller"

const application = Application.start()
application.register("email-builder", EmailBuilderController)
application.register("select", SelectController)
application.register("choices", ChoicesController)
