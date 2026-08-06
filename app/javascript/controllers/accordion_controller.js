import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["panel", "npanel", "menu", "response"];
  
  initialize() {
    document.addEventListener("click", this.closeMenuOutside.bind(this));
  }
  
  connect() {
    this.searchTimeout = null;
  }
  
  toggle(event) {
    const target = event.currentTarget;
    const panel = target.nextElementSibling;
    
    if (panel.classList.contains('visible')) {
      panel.classList.toggle('visible');
      panel.previousElementSibling.classList.remove("active-accordian");
      panel.parentElement.classList.remove("active-config-item");
    } else {
      panel.classList.toggle('visible'); 
      panel.previousElementSibling.classList.add("active-accordian");
      panel.parentElement.classList.add("active-config-item");
    }
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
  
  toggleMenu() {
    this.menuTarget.classList.toggle('visible');
  }
  
  preventSubmit(event) {
    event.preventDefault();
  }
  
  closeMenuOutside(event) {
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.menuTarget.classList.remove("visible");
      if (this.hasPanelTarget) {
        this.panelTarget.style.display = 'none';
        this.panelTarget.classList.remove("visible");
      }
    }
  }
}