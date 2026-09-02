import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggler"
export default class extends Controller {
  static targets = ["conversation", "ticket", "link", "hide", "sidebar", "sidebarToggle", "sidebarBackdrop"];

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
    this.handleResize = this.handleResize.bind(this);

    document.addEventListener("keydown", this.handleKeydown);
    window.addEventListener("resize", this.handleResize);
    this.syncSidebarAccessibility();
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
    window.removeEventListener("resize", this.handleResize);
  }

  toggleSidebar() {
    if (this.isSidebarDrawerViewport()) {
      const open = this.sidebarTarget.classList.toggle("is-drawer-open");
      this.element.classList.toggle("is-sidebar-drawer-open", open);
      this.syncSidebarAccessibility();
      return;
    }

    const collapsed = this.sidebarTarget.classList.toggle("is-collapsed");
    this.sidebarToggleTarget.setAttribute("aria-expanded", String(!collapsed));
  }

  closeSidebar(event) {
    event?.preventDefault?.();
    if (!this.hasSidebarTarget) return;

    const wasOpen = this.sidebarTarget.classList.contains("is-drawer-open");
    this.sidebarTarget.classList.remove("is-drawer-open");
    this.element.classList.remove("is-sidebar-drawer-open");
    this.syncSidebarAccessibility();

    if (wasOpen && event?.type !== "resize") this.sidebarToggleTarget?.focus();
  }

  handleKeydown(event) {
    if (
      event.key === "Escape" &&
      this.hasSidebarTarget &&
      this.sidebarTarget.classList.contains("is-drawer-open")
    ) {
      this.closeSidebar(event);
    }
  }

  handleResize() {
    if (!this.hasSidebarTarget) return;
    if (!this.isSidebarDrawerViewport()) this.closeSidebar({ type: "resize" });
    this.syncSidebarAccessibility();
  }

  isSidebarDrawerViewport() {
    return window.matchMedia("(min-width: 601px) and (max-width: 900px)")
      .matches;
  }

  syncSidebarAccessibility() {
    if (!this.hasSidebarTarget || !this.hasSidebarToggleTarget) return;

    const expanded = this.isSidebarDrawerViewport()
      ? this.sidebarTarget.classList.contains("is-drawer-open")
      : !this.sidebarTarget.classList.contains("is-collapsed");

    this.sidebarToggleTarget.setAttribute("aria-expanded", String(expanded));
  }

  openSearch() {
    window.dispatchEvent(new CustomEvent("deskbolic:smart-search-open"));
  }

  toggle_link(event) {
    const target = event.currentTarget;
    this.linkTargets.forEach((linkTarget) => {
      if (linkTarget !== target) {
        linkTarget.classList.remove("active-tab");
      }
    });

    this.hideTargets.forEach((hideTarget) => {
      hideTarget.style.display = "none";
    });

    target.classList.add("active-tab");
    this[event.target.dataset.itemNameParam + "Target"].style.display = "block";
  }
}
