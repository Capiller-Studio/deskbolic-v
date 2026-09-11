export default function registerPageController(identifier, controller) {
  if (!window.Stimulus) {
    throw new Error(`Cannot register ${identifier}: the dashboard Stimulus application is not loaded`)
  }

  window.Stimulus.register(identifier, controller)
}
