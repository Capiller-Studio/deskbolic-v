import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["panel", "npanel", "menu", "response"];
  static values = { exclusive: Boolean };

  initialize() {
    this.boundCloseMenuOutside = this.closeMenuOutside.bind(this);
  }

  connect() {
    this.searchTimeout = null;
    document.addEventListener("click", this.boundCloseMenuOutside);
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseMenuOutside);
  }
  
  toggle(event) {
    const target = event.currentTarget;
    const panel = target.nextElementSibling;

    if (!panel || !this.panelTargets.includes(panel)) return;

    const opening = !panel.classList.contains("visible");

    if (opening && panel.closest(".agent, .team")) {
      this.panelTargets.forEach((otherPanel) => {
        if (otherPanel !== panel && otherPanel.closest(".agent, .team")) {
          this.setPanelState(otherPanel, false);
        }
      });
    }

    if (opening && this.exclusiveValue) {
      this.panelTargets.forEach((otherPanel) => {
        if (otherPanel !== panel) this.setPanelState(otherPanel, false);
      });
    }

    this.setPanelState(panel, opening);
  }

  setPanelState(panel, open) {
    const trigger = panel.previousElementSibling;

    panel.classList.toggle("visible", open);
    trigger?.classList.toggle("active-accordian", open);
    trigger?.setAttribute("aria-expanded", open.toString());
    panel.parentElement.classList.toggle("active-config-item", open);
  }
  
  toggleNote(event) {
    const panel = this.npanelTarget;
    
    if (panel.classList.contains('visible')) {
      panel.classList.toggle('visible');
    } else {
      panel.classList.toggle('visible'); 
    }
    event.stopPropagation();
  }
  
  preventBlankNote(event) {
    const noteField = event.currentTarget.querySelector('textarea[name="note[content]"]');
    if (!noteField) return;

    noteField.value = noteField.value.trim();
    if (noteField.value === '') {
      event.preventDefault();
      noteField.classList.add('is-invalid');
      noteField.setAttribute('aria-invalid', 'true');
      noteField.focus();
    }
  }

  clearNoteValidation(event) {
    if (event.currentTarget.value.trim() === '') return;

    event.currentTarget.classList.remove('is-invalid');
    event.currentTarget.removeAttribute('aria-invalid');
  }

  clearNote(event) {
    if (!event.detail.success) return;

    const noteField = this.npanelTarget.querySelector(".note-field");
    if(noteField) noteField.value = '';
    this.npanelTarget.classList.remove('visible');
  }
  
  addTag(event) {
    const tagValue = event.currentTarget.dataset.value;
    const textarea = this.responseTarget;
    const cursorPos = textarea.selectionStart;

    const textBefore = textarea.value.substring(0, cursorPos);
    const textAfter = textarea.value.substring(cursorPos);
    textarea.value = `${textBefore}${tagValue}${textAfter}`;

    textarea.selectionStart = textarea.selectionEnd = cursorPos + tagValue.length;

    textarea.focus();
  }
  
  toggleMenu(event) {
    const opening = !this.menuTarget.classList.contains("visible");

    this.menuTarget.classList.toggle("visible", opening);
    event?.currentTarget?.setAttribute("aria-expanded", opening.toString());
  }
  
  preventSubmit(event) {
    event.preventDefault();
  }
  
  closeMenuOutside(event) {
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.menuTarget.classList.remove("visible");
      this.element
        .querySelectorAll('[data-action*="accordion#toggleMenu"]')
        .forEach((trigger) => trigger.setAttribute("aria-expanded", "false"));
    }

    this.panelTargets.forEach((panel) => {
      const assignmentField = panel.closest(".agent, .team");
      if (assignmentField && !assignmentField.contains(event.target)) {
        this.setPanelState(panel, false);
      }
    });
  }
}
