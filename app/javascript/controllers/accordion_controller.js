import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["panel", "npanel", "menu", "response"];
  
  initialize() {
    document.addEventListener("click", this.closeMenuOutside.bind(this));
  }
  
  toggle(event) {
    const target = event.currentTarget;
    const panel = target.nextElementSibling;
    
    if (panel.classList.contains('visible')) {
      panel.classList.toggle('visible');
      panel.previousElementSibling.classList.remove("active-accordian");
    } else {
      panel.classList.toggle('visible'); 
      panel.previousElementSibling.classList.add("active-accordian");
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
  addNote() {
    const panel = document.querySelector(".notes-panel");
    const noteField = document.querySelector(".note-field");
    const noteContent = noteField.value.trim();
  
    if (noteContent) {
      this.postNote(noteContent).then(success => {
        if (success) {
          const note = document.createElement('p');
          note.classList.add('f-reg-12');
          note.textContent = noteContent;
          panel.appendChild(note);

          noteField.value = '';
          this.npanelTarget.classList.toggle('visible');
        }
      }).catch(error => {
        console.error('Error saving note:', error);
      });
    }
  }
  
  postNote(noteContent) {
    return new Promise((resolve, reject) => {
      fetch('/notes', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({ note: { content: noteContent } })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          resolve(true);
        } else {
          resolve(false);
        }
      })
      .catch(error => {
        reject(error);
      });
    });
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
  
  togglePanel(event) {
    const targetTitle = event.currentTarget.dataset.title;
    const targetDesc = event.currentTarget.dataset.description;

    this.responseTarget.innerHTML = `
    <p class='f-semi-18 response-title'>${targetTitle}</p>
    <p class='f-reg-14 response-text'>${targetDesc}</p>`;
    
    this.panelTarget.classList.add('visible');
  }
  
  switchResponse() {
    const canned_response = this.responseTarget.querySelector(".response-text").textContent;
    document.querySelector(".response-area").value = canned_response;
    this.menuTarget.classList.toggle('visible');
  }
  
  closeMenuOutside(event) {
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.menuTarget.classList.remove("visible");
    }
  }
}