import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static targets = ["dialog", "title", "message", "confirmButton"];

  static values = {
    title: String,
    confirmLabel: String,
    deleteLabel: String,
  };

  connect() {
    this.confirmMethod = this.confirm.bind(this);
    this.previousConfirmMethod = Turbo.config.forms.confirm;
    Turbo.config.forms.confirm = this.confirmMethod;
  }

  disconnect() {
    if (Turbo.config.forms.confirm === this.confirmMethod) {
      Turbo.config.forms.confirm = this.previousConfirmMethod;
    }

    this.finish(false);
  }

  confirm(message, form, submitter) {
    if (
      !this.hasDialogTarget ||
      typeof this.dialogTarget.showModal !== "function"
    ) {
      return Promise.resolve(window.confirm(message));
    }

    if (this.resolveConfirmation) this.finish(false);

    const destructive = this.isDestructive(form, submitter);
    const title =
      this.dataAttribute("confirmTitle", form, submitter) || this.titleValue;
    const buttonLabel =
      this.dataAttribute("confirmButton", form, submitter) ||
      this.defaultButtonLabel(destructive, submitter);

    this.titleTarget.textContent = title;
    this.messageTarget.textContent = message;
    this.confirmButtonTarget.textContent = buttonLabel;
    this.dialogTarget.classList.toggle(
      "confirmation-dialog--danger",
      destructive,
    );
    document.body.classList.add("confirmation-dialog-open");

    return new Promise((resolve) => {
      this.resolveConfirmation = resolve;
      this.dialogTarget.showModal();
    });
  }

  accept() {
    this.finish(true);
  }

  cancel(event) {
    event?.preventDefault();
    this.finish(false);
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.cancel(event);
  }

  finish(confirmed) {
    if (this.hasDialogTarget && this.dialogTarget.open)
      this.dialogTarget.close();
    document.body.classList.remove("confirmation-dialog-open");

    if (this.resolveConfirmation) {
      const resolve = this.resolveConfirmation;
      this.resolveConfirmation = null;
      resolve(confirmed);
    }
  }

  isDestructive(form, submitter) {
    const variant = this.dataAttribute("confirmVariant", form, submitter);
    if (variant) return variant === "danger";

    const method =
      submitter?.getAttribute("formmethod") ||
      form?.querySelector('input[name="_method"]')?.value ||
      form?.getAttribute("method");

    return method?.toLowerCase() === "delete";
  }

  defaultButtonLabel(destructive, submitter) {
    if (destructive) return this.deleteLabelValue;

    const submitterLabel = submitter?.value || submitter?.textContent?.trim();
    return submitterLabel || this.confirmLabelValue;
  }

  dataAttribute(name, form, submitter) {
    return submitter?.dataset[name] || form?.dataset[name];
  }
}
