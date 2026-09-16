import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="formWizard"
export default class extends Controller {
  static targets = [
    "nextButton",
    "previousButton",
    "roleRadio",
    "companyTaxable",
    "vehicleOwnerRadio",
    "companyTaxableRadio",
    "formProgressbar",
    "companyInput",
    "companyTaxableInput",
    "vehicleOwnerInput",
  ];

  nextStep(event) {
    
    event.preventDefault();
    const currentFs = event.currentTarget.closest("fieldset");
    const form = event.currentTarget.closest("form");
    
    let nextFs = currentFs.nextElementSibling;
    while (nextFs && nextFs.style.display === 'none') {
      nextFs = nextFs.nextElementSibling;
    }
    
    const isValid = [...currentFs.querySelectorAll("input, select, textarea")]
      .every(input => input.checkValidity());
    if (!isValid || !nextFs) return;

    nextFs.querySelectorAll("input").forEach(input => input.disabled = false);
    
    this.roleRadioTargets.forEach(radio => radio.dispatchEvent(new Event("change")));
    this.animateFieldset(currentFs, nextFs);
  }

  nextEmailStep(event) {
    event.preventDefault();
    const currentFs = event.currentTarget.closest("fieldset");
    const nextFs = currentFs.nextElementSibling;
    if (!nextFs) return;

    nextFs.querySelectorAll("input").forEach(input => input.disabled = false);
    this.animateFieldset(currentFs, nextFs);
  }

  animateFieldset(fromFs, toFs) {
    fromFs.style.opacity = 1;
    toFs.style.display = "none";
    fromFs.animate([{ opacity: 1 }, { opacity: 0 }], {
      duration: 600,
      fill: "forwards",
    }).onfinish = () => {
      fromFs.style.display = "none";
      toFs.style.display = "block";
      toFs.style.opacity = 0;
      toFs.animate([{ opacity: 0 }, { opacity: 1 }], {
        duration: 600,
        fill: "forwards",
      });
    };
  }
  
  
  toggleFieldsets() {
    const selectedRole = this.roleRadioTargets.find(radio => radio.checked)?.value;
    const agentFieldsets = document.querySelectorAll('fieldset.agent-section');
    const companyFieldsets = document.querySelectorAll('fieldset.company-section');
    if (selectedRole === 'agent') {
      agentFieldsets[0].style.display = 'block';
      companyFieldsets.forEach(fieldset => fieldset.style.display = 'none');
    } else if (selectedRole === 'company') {
      companyFieldsets[0].style.display = 'block';
      agentFieldsets.forEach(fieldset => fieldset.style.display = 'none');
    }
  }
}