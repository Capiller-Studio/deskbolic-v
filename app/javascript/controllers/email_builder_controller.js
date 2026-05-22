import { Controller } from "@hotwired/stimulus"
import grapesjs from "grapesjs"
import grapesjsMjml from "grapesjs-mjml"

/**
 * EmailBuilderController
 *
 * Drag-and-drop email template editor built on GrapeJS + MJML.
 * Implements a safe draft/publish workflow:
 *   - Save Draft: writes to draft fields only (live template unaffected)
 *   - Publish: explicit action that copies draft → live with confirmation
 *   - Preview: renders compiled draft with sample variables in a modal
 *   - Send Test: sends test email using draft content
 *
 * Stimulus values:
 *   - update-url: PATCH endpoint for saving draft
 *   - publish-url: POST endpoint for publishing
 *   - discard-url: POST endpoint for discarding draft
 *   - preview-url: GET endpoint for preview HTML
 *   - send-test-url: POST endpoint for sending test
 *   - upload-url: POST endpoint for image uploads
 *   - design: JSON string of saved GrapeJS project data
 *   - variables: JSON string of available template variables
 *   - csrf-token: Rails CSRF token
 *   - has-unpublished-changes: boolean
 *   - locale: current editing locale
 */
export default class extends Controller {
  static values = {
    updateUrl: String,
    publishUrl: String,
    discardUrl: String,
    previewUrl: String,
    sendTestUrl: String,
    uploadUrl: String,
    copyLocaleUrl: { type: String, default: "" },
    design: { type: Object, default: {} },
    draftBody: { type: String, default: "" },
    variables: { type: Object, default: {} },
    csrfToken: String,
    hasUnpublishedChanges: { type: Boolean, default: false },
    locale: { type: String, default: "en" },
  }

  static targets = [
    "canvas",
    "blocksPanel",
    "stylesPanel",
    "variablesPanel",
    "previewModal",
    "previewFrame",
    "toastContainer",
    "copyMenu",
    "addLocaleMenu",
    "settingsPanel",
    "subjectInput",
    "subjectModal",
  ]

  connect() {
    this.isDirty = false
    this.initEditor()
    this._closeMenusBound = this._closeMenusOnOutsideClick.bind(this)
    document.addEventListener("click", this._closeMenusBound)
  }

  disconnect() {
    document.removeEventListener("click", this._closeMenusBound)
    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
  }

  // ─── Editor Initialization ──────────────────────────────────────────

  initEditor() {
    this.editor = grapesjs.init({
      container: this.canvasTarget,
      height: "100%",
      width: "auto",
      fromElement: false,
      storageManager: false,

      // Use MJML plugin
      plugins: [grapesjsMjml],
      pluginsOpts: {
        [grapesjsMjml]: {
          // Don't reset on import
          resetStyleManager: false,
        },
      },

      // Asset manager for image uploads
      assetManager: {
        upload: this.uploadUrlValue,
        uploadName: "file",
        headers: {
          "X-CSRF-Token": this.csrfTokenValue,
        },
        multiUpload: false,
        autoAdd: true,
      },

      // Trait manager config (for Settings tab)
      traitManager: {
        appendTo: this.settingsPanelTarget,
      },

      // Style manager config
      styleManager: {
        appendTo: this.stylesPanelTarget,
      },

      // Block manager config
      blockManager: {
        appendTo: this.blocksPanelTarget,
      },

      // Hide default panels — we use our own custom UI
      panels: { defaults: [] },

      // Canvas styling
      canvas: {
        styles: [
          "https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap",
        ],
      },

      // Device manager for responsive preview
      deviceManager: {
        devices: [
          { name: "Desktop", width: "" },
          { name: "Tablet", width: "768px", widthMedia: "992px" },
          { name: "Mobile", width: "375px", widthMedia: "480px" },
        ],
      },
    })

    this.configureCustomBlocks()
    this.loadDesign()
    this.bindEditorEvents()
  }

  // ─── Custom MJML Blocks ─────────────────────────────────────────────

  configureCustomBlocks() {
    const bm = this.editor.BlockManager

    // Clear default blocks that come with the plugin
    bm.getAll().reset()

    bm.add("mj-section", {
      label: "Section",
      category: "Layout",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="6" width="18" height="12" rx="2"/></svg>`,
      content: `<mj-section><mj-column><mj-text>Section content</mj-text></mj-column></mj-section>`,
    })

    bm.add("mj-columns-2", {
      label: "2 Columns",
      category: "Layout",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="6" width="8" height="12" rx="1"/><rect x="13" y="6" width="8" height="12" rx="1"/></svg>`,
      content: `<mj-section><mj-column><mj-text>Column 1</mj-text></mj-column><mj-column><mj-text>Column 2</mj-text></mj-column></mj-section>`,
    })

    bm.add("mj-text", {
      label: "Text",
      category: "Content",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M4 7V4h16v3M9 20h6M12 4v16"/></svg>`,
      content: `<mj-text font-size="16px" color="#4b5563" line-height="24px">Your text here</mj-text>`,
    })

    bm.add("mj-image", {
      label: "Image",
      category: "Content",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="9" cy="9" r="2"/><path d="M21 15l-5-5L5 21"/></svg>`,
      content: `<mj-image src="https://placehold.co/600x200/2563eb/ffffff?text=Your+Image" alt="Image" padding="10px 0" />`,
    })

    bm.add("mj-button", {
      label: "Button",
      category: "Content",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="4" y="8" width="16" height="8" rx="4"/><path d="M9 12h6"/></svg>`,
      content: `<mj-button background-color="#2563eb" color="#ffffff" font-weight="600" border-radius="6px" font-size="16px" inner-padding="12px 30px" href="#">Click Here</mj-button>`,
    })

    bm.add("mj-divider", {
      label: "Divider",
      category: "Content",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><line x1="3" y1="12" x2="21" y2="12"/></svg>`,
      content: `<mj-divider border-color="#e5e7eb" border-width="1px" padding="15px 0" />`,
    })

    bm.add("mj-spacer", {
      label: "Spacer",
      category: "Content",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 5v14M5 8l7-3 7 3M5 16l7 3 7-3"/></svg>`,
      content: `<mj-spacer height="30px" />`,
    })

    bm.add("mj-social", {
      label: "Social Links",
      category: "Content",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><circle cx="12" cy="12" r="9"/><path d="M8 12a4 4 0 018 0M15 9.5l-3 5-3-5"/></svg>`,
      content: `<mj-social font-size="15px" icon-size="30px" mode="horizontal"><mj-social-element name="facebook" href="#">Facebook</mj-social-element><mj-social-element name="twitter" href="#">Twitter</mj-social-element><mj-social-element name="linkedin" href="#">LinkedIn</mj-social-element></mj-social>`,
    })

    bm.add("mj-hero", {
      label: "Hero",
      category: "Composed",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M7 13h10M9 17h6M8 9h8"/></svg>`,
      content: `<mj-section background-color="#2563eb" padding="40px 20px"><mj-column><mj-text color="#ffffff" font-size="28px" font-weight="700" align="center">Your Headline Here</mj-text><mj-text color="#dbeafe" font-size="16px" align="center" padding-top="10px">Add a compelling subtitle to engage your readers.</mj-text><mj-button background-color="#ffffff" color="#2563eb" font-weight="600" border-radius="6px" font-size="16px" inner-padding="12px 30px" href="#" padding-top="20px">Get Started</mj-button></mj-column></mj-section>`,
    })

    bm.add("mj-footer", {
      label: "Footer",
      category: "Composed",
      media: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="14" width="18" height="7" rx="1"/><line x1="3" y1="14" x2="21" y2="14"/><path d="M8 17h8"/></svg>`,
      content: `<mj-section background-color="#f3f4f6" padding="20px"><mj-column><mj-text align="center" color="#6b7280" font-size="12px" line-height="18px">&copy; {{account.name}} &bull; All rights reserved<br/><a href="#" style="color: #6b7280; text-decoration: underline;">Unsubscribe</a></mj-text></mj-column></mj-section>`,
    })
  }

  // ─── Design Load/Save ───────────────────────────────────────────────

  loadDesign() {
    const design = this.designValue
    if (design && Object.keys(design).length > 0) {
      // Load from saved GrapeJS project data (preserves full editor state)
      this.editor.loadProjectData(design)
    } else if (this.draftBodyValue && this.draftBodyValue.trim().length > 0) {
      // Fall back to importing MJML source (for seeded templates without design JSON)
      this.editor.setComponents(this.draftBodyValue)
    }
  }

  changeLocale(event) {
    const locale = event.target.value
    this.navigateToLocale(locale)
  }

  addLocale(event) {
    const locale = event.currentTarget.dataset.locale
    if (locale) {
      this.navigateToLocale(locale)
    }
  }

  navigateToLocale(locale) {
    const url = new URL(window.location.href)
    url.searchParams.delete("locale")
    url.searchParams.set("template_locale", locale)
    window.location.href = url.toString()
  }

  changeLayout(event) {
    // Layout change will be saved with the next draft save
    this.isDirty = true
  }

  async save() {
    if (this._saving) return
    this._saving = true

    const saveBtn = document.getElementById("eb-save-btn")
    if (saveBtn) {
      saveBtn.disabled = true
      saveBtn.textContent = saveBtn.dataset.savingText || "Saving..."
    }

    try {
      const projectData = this.editor.getProjectData()
      const mjmlSource = this.getMjmlSource()

      const payload = {
        template_locale: this.localeValue,
        email_template: {
          draft_body: mjmlSource,
          draft_design: projectData,
        },
      }

      if (this.hasSubjectInputTarget) {
        payload.email_template.draft_subject = this.subjectInputTarget.value
      }

      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify(payload),
      })

      const data = await response.json()

      if (data.success) {
        this.isDirty = false
        this.hasUnpublishedChangesValue = true
        this.updatePublishVisibility()
        this.showToast(data.message, "success")
      } else {
        this.showToast(data.errors?.join(", ") || "Save failed", "error")
      }
    } catch (err) {
      this.showToast(`Save failed: ${err.message}`, "error")
    } finally {
      this._saving = false
      if (saveBtn) {
        saveBtn.disabled = false
        saveBtn.textContent = saveBtn.dataset.defaultText || "Save Draft"
      }
    }
  }

  async publish() {
    if (!confirm("This will update the live template. Emails sent after this will use the new design. Continue?")) {
      return
    }

    // Save draft first if dirty
    if (this.isDirty) await this.save()

    try {
      const response = await fetch(this.publishUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify({ template_locale: this.localeValue }),
      })

      const data = await response.json()

      if (data.success) {
        this.hasUnpublishedChangesValue = false
        this.updatePublishVisibility()
        this.showToast(data.message, "success")
      } else {
        this.showToast(data.errors?.join(", ") || "Publish failed", "error")
      }
    } catch (err) {
      this.showToast(`Publish failed: ${err.message}`, "error")
    }
  }

  async discardDraft() {
    if (!confirm("This will discard all unpublished changes and reset to the last published version. Continue?")) {
      return
    }

    try {
      const response = await fetch(this.discardUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify({ template_locale: this.localeValue }),
      })

      const data = await response.json()

      if (data.success) {
        this.hasUnpublishedChangesValue = false
        this.updatePublishVisibility()
        this.showToast(data.message, "success")
        // Reload to get fresh draft content
        window.location.reload()
      } else {
        this.showToast(data.errors?.join(", ") || "Discard failed", "error")
      }
    } catch (err) {
      this.showToast(`Discard failed: ${err.message}`, "error")
    }
  }

  // ─── Preview ────────────────────────────────────────────────────────

  async preview() {
    // Always save draft before preview so the layout compiles with the latest content
    await this.save()

    try {
      const response = await fetch(
        `${this.previewUrlValue}?template_locale=${this.localeValue}`,
        {
          headers: {
            Accept: "application/json",
          },
        }
      )

      const data = await response.json()
      if (data.html !== undefined) {
        this.previewFrameTarget.srcdoc = data.html
        this.previewModalTarget.classList.add("eb-modal--open")
      }
    } catch (err) {
      this.showToast("Failed to load preview", "error")
    }
  }

  closePreview(event) {
    if (!event || event.currentTarget.tagName === 'BUTTON' || event.target === event.currentTarget) {
      this.previewModalTarget.classList.remove("eb-modal--open")
    }
  }

  setPreviewDevice(event) {
    const device = event.currentTarget.dataset.device || "desktop"
    this.previewFrameTarget.style.maxWidth = device === "mobile" ? "375px" : "100%"

    document.querySelectorAll(".eb-preview__device").forEach((btn) => {
      btn.classList.toggle("eb-preview__device--active", btn.dataset.device === device)
    })
  }

  // ─── Subject Modal ──────────────────────────────────────────────────

  openSubjectModal() {
    if (this.hasSubjectModalTarget) {
      this.subjectModalTarget.classList.add("eb-modal--open")
    }
  }

  closeSubjectModal(event) {
    if (!event || event.currentTarget.tagName === 'BUTTON' || event.target === event.currentTarget) {
      if (this.hasSubjectModalTarget) {
        this.subjectModalTarget.classList.remove("eb-modal--open")
        this.isDirty = true // Mark as dirty when they close the modal, assuming they edited it
      }
    }
  }

  // ─── Send Test ──────────────────────────────────────────────────────

  async sendTest() {
    if (this.isDirty) await this.save()

    try {
      const response = await fetch(this.sendTestUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify({ template_locale: this.localeValue }),
      })

      const data = await response.json()

      if (data.success) {
        this.showToast(data.message, "success")
      } else {
        this.showToast(data.errors?.join(", ") || "Send failed", "error")
      }
    } catch (err) {
      this.showToast(`Send test failed: ${err.message}`, "error")
    }
  }

  // ─── Variable Insertion ─────────────────────────────────────────────

  preventFocus(event) {
    event.preventDefault()
  }

  insertVariable(event) {
    const variable = event.currentTarget.dataset.variable
    if (!variable) return

    const rte = this.editor.RichTextEditor
    if (rte && rte.isActive) {
      rte.insertHTML(variable)
      this.isDirty = true
      this.showToast(`Inserted ${variable}`, "info")
      return
    }

    const selected = this.editor.getSelected()
    if (selected && selected.get("type") === "mj-text") {
      // Append variable tag to the selected text component
      const currentContent = selected.components().models.map(c => c.toHTML()).join("") || selected.get("content") || ""
      selected.components(`${currentContent} ${variable}`)
    } else {
      // If no text block selected, add a new text block with the variable
      const wrapper = this.editor.getWrapper()
      const body = wrapper.find("mj-body")[0] || wrapper
      const sections = body.find("mj-section")

      if (sections.length > 0) {
        const lastSection = sections[sections.length - 1]
        const columns = lastSection.find("mj-column")
        if (columns.length > 0) {
          columns[0].append(
            `<mj-text font-size="16px" color="#4b5563">${variable}</mj-text>`
          )
        }
      }
    }

    this.isDirty = true
    this.showToast(`Inserted ${variable}`, "info")
  }

  // ─── Device Toggle ──────────────────────────────────────────────────

  toggleDevice(event) {
    const device = event.currentTarget.dataset.device || "Desktop"
    this.editor.setDevice(device)

    document.querySelectorAll("[data-action*='toggleDevice']").forEach((btn) => {
      btn.classList.toggle("eb-toolbar__device--active", btn.dataset.device === device)
    })
  }

  // ─── Tab Switching ──────────────────────────────────────────────────

  switchTab(event) {
    const targetTab = event.currentTarget.dataset.tab

    // Update tab buttons
    document.querySelectorAll(".eb-sidebar__tab").forEach((tab) => {
      tab.classList.toggle("eb-sidebar__tab--active", tab.dataset.tab === targetTab)
    })

    // Update panels
    document.querySelectorAll(".eb-sidebar__panel").forEach((panel) => {
      panel.classList.toggle(
        "eb-sidebar__panel--active",
        panel.dataset.panel === targetTab
      )
    })
  }

  // ─── Copy Locale ────────────────────────────────────────────────────

  toggleCopyMenu(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (this.hasCopyMenuTarget) {
      this.copyMenuTarget.classList.toggle("eb-toolbar__copy-menu--open")
    }
    if (this.hasAddLocaleMenuTarget) {
      this.addLocaleMenuTarget.classList.remove("eb-toolbar__copy-menu--open")
    }
  }

  toggleAddLocaleMenu(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (this.hasAddLocaleMenuTarget) {
      this.addLocaleMenuTarget.classList.toggle("eb-toolbar__copy-menu--open")
    }
    if (this.hasCopyMenuTarget) {
      this.copyMenuTarget.classList.remove("eb-toolbar__copy-menu--open")
    }
  }

  _closeMenusOnOutsideClick(event) {
    if (this.hasCopyMenuTarget && this.copyMenuTarget.classList.contains("eb-toolbar__copy-menu--open")) {
      const isClickInside = this.copyMenuTarget.contains(event.target) ||
        event.target.closest("[data-action*='toggleCopyMenu']")

      if (!isClickInside) {
        this.copyMenuTarget.classList.remove("eb-toolbar__copy-menu--open")
      }
    }

    if (this.hasAddLocaleMenuTarget && this.addLocaleMenuTarget.classList.contains("eb-toolbar__copy-menu--open")) {
      const isClickInside = this.addLocaleMenuTarget.contains(event.target) ||
        event.target.closest("[data-action*='toggleAddLocaleMenu']")

      if (!isClickInside) {
        this.addLocaleMenuTarget.classList.remove("eb-toolbar__copy-menu--open")
      }
    }
  }

  async copyFromLocale(event) {
    event.preventDefault()

    const sourceLocale = event.currentTarget.dataset.sourceLocale
    if (!sourceLocale) return

    // Close the menu
    if (this.hasCopyMenuTarget) {
      this.copyMenuTarget.classList.remove("eb-toolbar__copy-menu--open")
    }

    if (!confirm(`Are you sure you want to overwrite current content with ${sourceLocale.toUpperCase()}? Unsaved changes will be lost.`)) {
      return
    }

    try {
      const response = await fetch(this.copyLocaleUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify({
          source_locale: sourceLocale,
          target_locale: this.localeValue
        }),
      })

      const data = await response.json()

      if (data.success) {
        this.showToast(data.message, "success")
        // Reload page to see copied content by navigating to the current locale
        setTimeout(() => {
          this.navigateToLocale(this.localeValue)
        }, 1000)
      } else {
        this.showToast(data.errors?.join(", ") || "Failed to copy locale", "error")
      }
    } catch (err) {
      this.showToast(`Failed to copy locale: ${err.message}`, "error")
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  getMjmlSource() {
    // Extract MJML from GrapeJS component model
    const editor = this.editor
    try {
      // In older grapesjs-mjml, this command existed. In newer ones, getHtml() does it natively.
      const mjml = editor.runCommand("mjml-get-code")
      if (mjml && mjml.html) {
        return mjml.html // Some versions return html property
      }
      if (mjml && mjml.mjml) {
        return mjml.mjml
      }
      return editor.getHtml() || ""
    } catch {
      return editor.getHtml() || ""
    }
  }

  bindEditorEvents() {
    this.editor.on("change:changesCount", () => {
      this.isDirty = true
    })

    // Override RTE alignment to modify the mj-text component directly, since MJML strips inline text-align.
    // First remove existing native buggy actions so we don't get duplicates
    try {
      this.editor.RichTextEditor.remove('link');
      this.editor.RichTextEditor.remove('unlink');
    } catch (e) { }

    const rteActions = [
      { id: 'link', action: 'link', icon: '<div class="eb-rte-icon eb-rte-icon-link"></div>', title: 'Insert Link' },
      { id: 'unlink', action: 'unlink', icon: '<div class="eb-rte-icon eb-rte-icon-unlink"></div>', title: 'Remove Link' },
      { id: 'wrap', action: 'wrap', icon: '<div class="eb-rte-icon eb-rte-icon-wrap"></div>', title: 'Wrap for style' },
      { id: 'justifyLeft', action: 'align', align: 'left', icon: '<div class="eb-rte-icon eb-rte-icon-align-left"></div>' },
      { id: 'justifyCenter', action: 'align', align: 'center', icon: '<div class="eb-rte-icon eb-rte-icon-align-center"></div>' },
      { id: 'justifyRight', action: 'align', align: 'right', icon: '<div class="eb-rte-icon eb-rte-icon-align-right"></div>' },
      { id: 'justifyFull', action: 'align', align: 'justify', icon: '<div class="eb-rte-icon eb-rte-icon-align-justify"></div>' }
    ]

    rteActions.forEach(action => {
      // Remove any existing action with the same ID first to prevent duplicates
      try { this.editor.RichTextEditor.remove(action.id); } catch (e) { }

      this.editor.RichTextEditor.add(action.id, {
        icon: action.icon,
        attributes: { title: action.title || `Align ${action.align}` },
        result: (rte, actionBtn) => {
          if (action.action === 'align') {
            const selected = this.editor.getSelected()
            if (selected && selected.get("type") === "mj-text") {
              selected.addAttributes({ align: action.align })
            } else {
              rte.exec(action.id)
            }
          } else if (action.action === 'link') {
            const selected = this.editor.getSelected();
            if (selected && selected.get("type") === "mj-button") {
              this.showToast("To add a link to a button, use the Settings panel.", "warning");
              return;
            }

            const selection = rte.selection().toString();
            if (!selection) return; // Prevent creating link without text

            let popup = document.getElementById('custom-rte-link-popup');
            if (!popup) {
              popup = document.createElement('div');
              popup.id = 'custom-rte-link-popup';
              popup.className = 'custom-rte-link-popup';

              const input = document.createElement('input');
              input.type = 'text';
              input.placeholder = 'https://...';

              const btn = document.createElement('button');
              btn.innerHTML = '&#10003;'; // Checkmark

              const closeBtn = document.createElement('button');
              closeBtn.innerHTML = '&#10005;'; // X
              closeBtn.style.marginLeft = '4px';
              closeBtn.style.color = 'var(--eb-text-secondary)';
              closeBtn.style.background = 'transparent';
              closeBtn.style.border = 'none';
              closeBtn.style.cursor = 'pointer';
              closeBtn.style.fontSize = '14px';

              popup.appendChild(input);
              popup.appendChild(btn);
              popup.appendChild(closeBtn);

              // Prevent mousedown from blurring the editor!
              popup.addEventListener('mousedown', (e) => {
                e.stopPropagation();
                if (e.target !== input && e.target !== btn && e.target !== closeBtn) {
                  e.preventDefault();
                  input.focus();
                }
              });

              const applyLink = () => {
                if (input.value) {
                  rte.exec('createLink', input.value);
                }
                popup.style.display = 'none';
              };

              btn.addEventListener('click', applyLink);
              closeBtn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                popup.style.display = 'none';
              });
              input.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  applyLink();
                }
              });

              // Append to the toolbar container
              const toolbar = actionBtn.btn.closest('.gjs-rte-toolbar');
              if (toolbar) {
                toolbar.style.position = 'relative';
                toolbar.appendChild(popup);
              } else {
                document.body.appendChild(popup);
              }
            }

            popup.style.display = 'flex';
            const inputField = popup.querySelector('input');
            inputField.value = 'https://';
            // We set a tiny timeout because focus might be stolen by the main click event
            setTimeout(() => inputField.focus(), 50);

          } else if (action.action === 'unlink') {
            rte.exec('unlink')
          } else if (action.action === 'wrap') {
            rte.exec('wrap')
          }
        }
      })
    })



    // Warn before leaving with unsaved changes
    window.addEventListener("beforeunload", (e) => {
      if (this.isDirty) {
        e.preventDefault()
        e.returnValue = ""
      }
    })
  }

  updatePublishVisibility() {
    const publishBtn = document.getElementById("eb-publish-btn")
    const discardBtn = document.getElementById("eb-discard-btn")
    const badge = document.getElementById("eb-draft-badge")

    const show = this.hasUnpublishedChangesValue

    if (publishBtn) publishBtn.style.display = show ? "" : "none"
    if (discardBtn) discardBtn.style.display = show ? "" : "none"
    if (badge) badge.style.display = show ? "" : "none"
  }

  showToast(message, type = "info") {
    const container = this.hasToastContainerTarget
      ? this.toastContainerTarget
      : document.body

    const toast = document.createElement("div")
    toast.className = `eb-toast eb-toast--${type}`
    toast.textContent = message

    container.appendChild(toast)

    // Trigger animation
    requestAnimationFrame(() => toast.classList.add("eb-toast--visible"))

    setTimeout(() => {
      toast.classList.remove("eb-toast--visible")
      setTimeout(() => toast.remove(), 300)
    }, 4000)
  }
}
