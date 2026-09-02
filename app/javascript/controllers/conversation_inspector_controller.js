import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["panel", "backdrop", "toggle", "close"];

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
    this.handleResize = this.handleResize.bind(this);

    document.addEventListener("keydown", this.handleKeydown);
    window.addEventListener("resize", this.handleResize);
    this.syncAccessibility();
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
    window.removeEventListener("resize", this.handleResize);
  }

  toggle(event) {
    event.preventDefault();

    if (this.element.classList.contains("is-inspector-open")) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    if (!this.isDrawerViewport()) return;

    this.element.classList.add("is-inspector-open");
    this.syncAccessibility();
    this.closeTarget?.focus();
  }

  close(event) {
    event?.preventDefault?.();

    const wasOpen = this.element.classList.contains("is-inspector-open");
    this.element.classList.remove("is-inspector-open");
    this.syncAccessibility();

    if (wasOpen && event?.type !== "resize") this.toggleTarget?.focus();
  }

  handleKeydown(event) {
    if (
      event.key === "Escape" &&
      this.element.classList.contains("is-inspector-open")
    ) {
      this.close(event);
    }
  }

  handleResize() {
    if (!this.isDrawerViewport()) this.close({ type: "resize" });
    this.syncAccessibility();
  }

  isDrawerViewport() {
    return window.matchMedia("(max-width: 1320px)").matches;
  }

  syncAccessibility() {
    if (!this.hasPanelTarget || !this.hasToggleTarget) return;

    const drawerViewport = this.isDrawerViewport();
    const open = this.element.classList.contains("is-inspector-open");

    this.toggleTarget.setAttribute(
      "aria-expanded",
      String(drawerViewport && open),
    );
    this.panelTarget.setAttribute(
      "aria-hidden",
      String(drawerViewport && !open),
    );
    this.panelTarget.setAttribute(
      "role",
      drawerViewport ? "dialog" : "complementary",
    );
  }
}