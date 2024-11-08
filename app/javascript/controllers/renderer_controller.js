import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output", "template", "nextButton", "radioButton"];

  connect() {
    this.radioButtonTargets.forEach((target) => {
      const render = target.getAttribute("data-render");
      if (target.checked && render && render.toString() === "true") {
        this.add();
      }
    });
  }

  add() {
    const content = this.templateTarget.innerHTML.replace(
      /NEW_RECORD/g,
      new Date().getTime()
    );
    if (this.outputTarget.innerHTML === "")
    {
      this.outputTarget.innerHTML = content;
    }
  }

  remove() {
    this.outputTarget.innerHTML = "";
  }

  skip() {
    this.outputTarget.innerHTML = "";
    this.nextButtonTarget.click();
  }

  radioToggle(event) {
    const render = event.target.getAttribute("data-render");
    if (render && render.toString() === "true") {
      this.add();
    } else {
      this.remove();
    }
  }
}
