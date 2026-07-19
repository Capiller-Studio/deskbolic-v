import { Controller } from "@hotwired/stimulus"
import { Editor, Node, mergeAttributes } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Underline from "@tiptap/extension-underline"
import TextAlign from "@tiptap/extension-text-align"
import Link from "@tiptap/extension-link"
import Placeholder from "@tiptap/extension-placeholder"
import { Table } from "@tiptap/extension-table"
import { TableRow } from "@tiptap/extension-table-row"
import { TableCell } from "@tiptap/extension-table-cell"
import { TableHeader } from "@tiptap/extension-table-header"
import HorizontalRule from "@tiptap/extension-horizontal-rule"
import Youtube from "@tiptap/extension-youtube"

// Custom extensions
import Callout from "../../tiptap/extensions/callout"
import { Accordion, AccordionSummary, AccordionContent } from "../../tiptap/extensions/accordion"
import ButtonBlock from "../../tiptap/extensions/button_block"
import FileAttachment from "../../tiptap/extensions/file_attachment"
import KeyboardShortcut from "../../tiptap/extensions/keyboard_shortcut"
import ApiEndpoint from "../../tiptap/extensions/api_endpoint"
import TerminalOutput from "../../tiptap/extensions/terminal_output"
import SlashCommands from "../../tiptap/slash_commands"

// Inline Image node (same as before but enhanced)
const Image = Node.create({
  name: 'image',
  group: 'block',
  atom: true,
  addAttributes() {
    return {
      src: { default: null },
      alt: { default: null },
      title: { default: null },
      width: { default: null },
      height: { default: null },
    }
  },
  parseHTML() { return [{ tag: 'img[src]' }] },
  renderHTML({ HTMLAttributes }) { return ['img', mergeAttributes(HTMLAttributes)] },
  addCommands() {
    return {
      setImage: options => ({ commands }) => {
        return commands.insertContent({ type: this.name, attrs: options })
      },
    }
  },
})

/**
 * ArticleEditorController
 *
 * Full-featured Tiptap article editor with:
 *   - Rich text editing (20+ block types)
 *   - Slash command menu ("/")
 *   - Draft/Publish workflow (save draft, publish, discard)
 *   - Locale switching + add locale + copy from locale
 *   - Image upload via Attachments model
 *   - Autosave with debounce
 *   - Revision history viewing
 *
 * Data values (set from the view):
 *   - update-url:    PATCH endpoint for saving draft
 *   - publish-url:   POST endpoint for publishing
 *   - discard-url:   POST endpoint for discarding draft
 *   - copy-locale-url: POST endpoint for copying locale
 *   - upload-url:    POST endpoint for image/file uploads (Attachments)
 *   - article-id:    Article ID
 *   - csrf-token:    Rails CSRF token
 *   - draft-content: HTML content of the draft
 *   - draft-title:   Title of the draft
 *   - locale:        Current editing locale
 *   - has-unpublished-changes: boolean
 *   - locales:       JSON array of available locales [{code, label}]
 *   - status:        Current article status (draft/published/archived)
 */
export default class extends Controller {
  static values = {
    updateUrl: String,
    publishUrl: String,
    discardUrl: String,
    copyLocaleUrl: { type: String, default: "" },
    uploadUrl: { type: String, default: "" },
    articleId: String,
    csrfToken: String,
    draftContent: { type: String, default: "" },
    draftTitle: { type: String, default: "" },
    locale: { type: String, default: "en" },
    hasUnpublishedChanges: { type: Boolean, default: false },
    locales: { type: Array, default: [] },
    status: { type: String, default: "draft" },
    editUrl: { type: String, default: "" },
    revisionsUrl: { type: String, default: "" },
  }

  static targets = [
    "editorContainer",
    "titleInput",
    "contentInput",
    "imageInput",
    "fileInput",
    "toastContainer",
    "localeMenu",
    "copyMenu",
    "addLocaleMenu",
    "draftBadge",
    "bubbleMenu",
    "plusMenu",
    "toolbar",
    "sidePanel",
    "relatedArticles",
    "tableMenu",
    "imagePopover",
    "accordionMenu",
    "imageAltInput",
    "imageWidthInput",
    "imageHeightInput",
    "linkPopover",
    "linkUrlInput",
    "youtubePopover",
    "youtubeUrlInput"
  ]

  connect() {
    this.isDirty = false
    this._saving = false
    this._autoSaveTimer = null
    this.initEditor()
    this._closeMenusBound = this._closeMenusOnOutsideClick.bind(this)
    document.addEventListener("click", this._closeMenusBound)

    this._openYoutubeBound = this._handleOpenYoutube.bind(this)
    window.addEventListener("article-editor:open-youtube", this._openYoutubeBound)

    // Warn on unsaved changes
    this._beforeUnload = (e) => {
      if (this.isDirty) {
        e.preventDefault()
        e.returnValue = ''
      }
    }
    window.addEventListener("beforeunload", this._beforeUnload)
  }

  disconnect() {
    document.removeEventListener("click", this._closeMenusBound)
    window.removeEventListener("article-editor:open-youtube", this._openYoutubeBound)
    window.removeEventListener("beforeunload", this._beforeUnload)
    if (this._autoSaveTimer) clearTimeout(this._autoSaveTimer)
    if (this.editor) {
      this.editor.destroy()
      this.editor = null
    }
  }

  _handleOpenYoutube(event) {
    this.showYoutubePopover(event.detail.coords)
  }

  // ─── Editor Initialization ──────────────────────────────────────────

  initEditor() {
    if (!this.hasEditorContainerTarget) {
      console.error("[ArticleEditor] Missing editor container target")
      return
    }

    const content = this.draftContentValue || '<p></p>'

    this.editor = new Editor({
      element: this.editorContainerTarget,
      content,
      extensions: [
        StarterKit.configure({
          heading: { levels: [1, 2, 3] },
          codeBlock: false, // We use our own code block
          horizontalRule: false,
        }),
        Underline,
        Image,
        TextAlign.configure({
          types: ['heading', 'paragraph'],
        }),
        Link.configure({
          openOnClick: false,
          HTMLAttributes: { target: '_blank', rel: 'noopener noreferrer' },
        }),
        Placeholder.configure({
          placeholder: 'Type "/" for commands, or start writing...',
        }),
        Table.configure({ resizable: true }),
        TableRow,
        TableCell,
        TableHeader,
        HorizontalRule,
        Youtube.configure({
          inline: false,
          HTMLAttributes: { class: 'hc-youtube-embed' },
        }),
        // Custom blocks
        Callout,
        Accordion,
        AccordionSummary,
        AccordionContent,
        ButtonBlock,
        FileAttachment,
        KeyboardShortcut,
        ApiEndpoint,
        TerminalOutput,
        SlashCommands,
      ],
      editorProps: {
        attributes: {
          class: 'hc-editor-content',
        },
      },
      editable: true,
      onUpdate: () => {
        this.isDirty = true
        this.updateDraftBadge(true)
        this.scheduleAutoSave()
        this.updateToolbarState(this.editor)
        
        if (this.hasContentInputTarget) {
          this.contentInputTarget.value = this.editor.getHTML()
        }
      },
      onSelectionUpdate: ({ editor }) => {
        this.updateBubbleMenu(editor)
        this.updatePlusMenu(editor)
        this.updateTableMenu(editor)
        this.updateImageMenu(editor)
        this.updateAccordionMenu(editor)
        this.updateToolbarState(editor)

        if (this.hasLinkPopoverTarget) {
          if (!this.linkPopoverTarget.contains(document.activeElement)) {
            this.linkPopoverTarget.classList.remove('hc-image-popover--visible')
          }
        }
        
        if (this.hasYoutubePopoverTarget) {
          if (!this.youtubePopoverTarget.contains(document.activeElement)) {
            this.youtubePopoverTarget.classList.remove('hc-image-popover--visible')
          }
        }
      },
    })

    // Set initial title
    if (this.hasTitleInputTarget) {
      this.titleInputTarget.value = this.draftTitleValue
      this.titleInputTarget.addEventListener('input', () => {
        this.isDirty = true
        this.updateDraftBadge(true)
        this.scheduleAutoSave()
      })
    }

    this.updateDraftBadge(this.hasUnpublishedChangesValue)
  }

  // ─── Toolbar Actions ────────────────────────────────────────────────

  toggleBold() { this.editor?.chain().focus().toggleBold().run() }
  toggleItalic() { this.editor?.chain().focus().toggleItalic().run() }
  toggleUnderline() { this.editor?.chain().focus().toggleUnderline().run() }
  toggleStrike() { this.editor?.chain().focus().toggleStrike().run() }
  toggleCode() { this.editor?.chain().focus().toggleCode().run() }
  toggleKbd() { this.editor?.chain().focus().toggleKbd().run() }
  toggleBulletList() { this.editor?.chain().focus().toggleBulletList().run() }
  toggleOrderedList() { this.editor?.chain().focus().toggleOrderedList().run() }
  toggleBlockquote() { this.editor?.chain().focus().toggleBlockquote().run() }
  toggleCodeBlock() { this.editor?.chain().focus().toggleCodeBlock().run() }
  setHorizontalRule() { this.editor?.chain().focus().setHorizontalRule().run() }
  alignLeft() { this.editor?.chain().focus().setTextAlign('left').run() }
  alignCenter() { this.editor?.chain().focus().setTextAlign('center').run() }
  alignRight() { this.editor?.chain().focus().setTextAlign('right').run() }

  setHeading(event) {
    const level = parseInt(event.currentTarget.value || event.currentTarget.dataset.level)
    if (level === 0) {
      this.editor?.chain().focus().setParagraph().run()
    } else {
      this.editor?.chain().focus().toggleHeading({ level }).run()
    }
  }

  insertTable() {
    this.editor?.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
  }

  tableAddColumnBefore() { this.editor?.chain().focus().addColumnBefore().run() }
  tableAddColumnAfter() { this.editor?.chain().focus().addColumnAfter().run() }
  tableDeleteColumn() { this.editor?.chain().focus().deleteColumn().run() }
  tableAddRowBefore() { this.editor?.chain().focus().addRowBefore().run() }
  tableAddRowAfter() { this.editor?.chain().focus().addRowAfter().run() }
  tableDeleteRow() { this.editor?.chain().focus().deleteRow().run() }
  tableDelete() { this.editor?.chain().focus().deleteTable().run() }

  accordionDelete() {
    // There is no native deleteAccordion command, we can just delete the selection
    // if the selection encompasses the accordion, or use keyboard delete
    if (this.editor.isActive('accordion')) {
      // Simplest way is to select the accordion node and delete it
      // For now, we can use clearNodes or deleteNode
      this.editor.commands.deleteNode('accordion')
    }
  }

  saveImageProperties(event) {
    event?.preventDefault()
    
    const alt = this.hasImageAltInputTarget ? this.imageAltInputTarget.value : ''
    const width = this.hasImageWidthInputTarget ? this.imageWidthInputTarget.value : ''
    const height = this.hasImageHeightInputTarget ? this.imageHeightInputTarget.value : ''
    
    if (this.currentImagePos != null) {
      this.editor.chain().focus().command(({ tr }) => {
        const node = tr.doc.nodeAt(this.currentImagePos)
        if (node && node.type.name === 'image') {
          tr.setNodeMarkup(this.currentImagePos, undefined, { ...node.attrs, alt, width, height })
          return true
        }
        return false
      }).run()
      this.imagePopoverTarget.classList.remove('hc-image-popover--visible')
    }
  }

  toggleLink() {
    if (!this.hasLinkPopoverTarget) return

    if (this.editor?.isActive('link')) {
      const url = this.editor.getAttributes('link').href || ''
      this.showLinkPopover(url)
    } else {
      this.showLinkPopover('')
    }
  }

  showLinkPopover(url) {
    const { view, state } = this.editor
    const { selection } = state
    const start = view.coordsAtPos(selection.from)
    
    this.linkPopoverTarget.style.left = `${start.left}px`
    this.linkPopoverTarget.style.top = `${start.top + 32}px`
    this.linkPopoverTarget.classList.add('hc-image-popover--visible')
    this.bubbleMenuTarget.classList.remove('hc-bubble-menu--visible')
    
    this.linkUrlInputTarget.value = url || ''
    setTimeout(() => this.linkUrlInputTarget.focus(), 10)
  }

  saveLink(event) {
    event?.preventDefault()
    const url = this.linkUrlInputTarget.value
    if (url) {
      this.editor.chain().focus().setLink({ href: url }).run()
    } else {
      this.editor.chain().focus().unsetLink().run()
    }
    this.linkPopoverTarget.classList.remove('hc-image-popover--visible')
  }

  removeLink(event) {
    event?.preventDefault()
    this.editor.chain().focus().unsetLink().run()
    this.linkPopoverTarget.classList.remove('hc-image-popover--visible')
  }

  // ─── Youtube Popover ───────────────────────────────────────────────

  openYoutubePopover(event) {
    if (!this.hasYoutubePopoverTarget) return
    
    // Read the passed coordinates from the custom event
    const coords = event.detail.coords
    this.youtubeUrlInputTarget.value = ''
    this.youtubeInsertPos = this.editor.state.selection.from
    
    this.youtubePopoverTarget.style.left = `${coords.left}px`
    this.youtubePopoverTarget.style.top = `${coords.top + 32}px`
    this.youtubePopoverTarget.classList.add('hc-image-popover--visible')
    
    setTimeout(() => this.youtubeUrlInputTarget.focus(), 10)
  }

  saveYoutube(event) {
    event?.preventDefault()
    const url = this.youtubeUrlInputTarget.value
    if (url) {
      this.editor.chain().focus().insertContentAt(this.youtubeInsertPos, {
        type: 'youtube',
        attrs: { src: url }
      }).run()
    }
    this.youtubePopoverTarget.classList.remove('hc-image-popover--visible')
  }

  cancelYoutube(event) {
    event?.preventDefault()
    this.youtubePopoverTarget.classList.remove('hc-image-popover--visible')
    this.editor.chain().focus().run()
  }

  // ─── Toolbar State ──────────────────────────────────────────────────

  updateToolbarState(editor) {
    if (!this.hasToolbarTarget) return

    const toggles = {
      'bold': editor.isActive('bold'),
      'italic': editor.isActive('italic'),
      'underline': editor.isActive('underline'),
      'strike': editor.isActive('strike'),
      'code': editor.isActive('code'),
      'bulletList': editor.isActive('bulletList'),
      'orderedList': editor.isActive('orderedList'),
      'blockquote': editor.isActive('blockquote'),
      'codeBlock': editor.isActive('codeBlock'),
      'link': editor.isActive('link'),
      'alignLeft': editor.isActive({ textAlign: 'left' }),
      'alignCenter': editor.isActive({ textAlign: 'center' }),
      'alignRight': editor.isActive({ textAlign: 'right' }),
    }

    Object.entries(toggles).forEach(([key, active]) => {
      this.toolbarTargets.forEach(btn => {
        if (btn.dataset.format === key) {
          btn.classList.toggle('hc-toolbar-btn--active', active)
          btn.classList.toggle('hc-bubble-btn--active', active)
        }
      })
    })

    // Heading select
    if (this.hasToolbarTarget) {
      const headingSelect = this.toolbarTarget.querySelector ? this.toolbarTarget.querySelector('[data-format="heading"]') : null
      if (headingSelect) {
        if (editor.isActive('heading', { level: 1 })) headingSelect.value = '1'
        else if (editor.isActive('heading', { level: 2 })) headingSelect.value = '2'
        else if (editor.isActive('heading', { level: 3 })) headingSelect.value = '3'
        else headingSelect.value = '0'
      }
    }
  }

  updateBubbleMenu(editor) {
    if (!this.hasBubbleMenuTarget) return

    // Do not show the text formatting bubble menu for these block nodes
    if (editor.isActive('image') || editor.isActive('table') || editor.isActive('accordion') || editor.isActive('callout') || editor.isActive('apiEndpoint') || editor.isActive('fileAttachment')) {
      this.bubbleMenuTarget.classList.remove('hc-bubble-menu--visible')
      return
    }

    const { from, to } = editor.state.selection
    if (from === to) {
      this.bubbleMenuTarget.classList.remove('hc-bubble-menu--visible')
      return
    }

    // Position bubble menu
    const { view } = editor
    const start = view.coordsAtPos(from)
    const end = view.coordsAtPos(to)

    const centerX = (start.left + end.right) / 2
    const topY = Math.min(start.top, end.top) - 48

    this.bubbleMenuTarget.style.left = `${centerX}px`
    this.bubbleMenuTarget.style.top = `${topY}px`
    this.bubbleMenuTarget.classList.add('hc-bubble-menu--visible')
  }

  updateTableMenu(editor) {
    if (!this.hasTableMenuTarget) return
    if (editor.isActive('table')) {
      const { view, state } = editor
      const { selection } = state
      const start = view.coordsAtPos(selection.from)
      
      this.tableMenuTarget.style.left = `${start.left}px`
      this.tableMenuTarget.style.top = `${start.top - 48}px`
      this.tableMenuTarget.classList.add('hc-bubble-menu--visible')
    } else {
      this.tableMenuTarget.classList.remove('hc-bubble-menu--visible')
    }
  }

  updateImageMenu(editor) {
    if (!this.hasImagePopoverTarget) return
    if (editor.isActive('image')) {
      const { view, state } = editor
      const { selection } = state
      const start = view.coordsAtPos(selection.from)
      
      // Populate inputs
      const node = state.doc.nodeAt(selection.from)
      if (node && node.type.name === 'image') {
        if (this.hasImageAltInputTarget) this.imageAltInputTarget.value = node.attrs.alt || ''
        if (this.hasImageWidthInputTarget) this.imageWidthInputTarget.value = node.attrs.width || ''
        if (this.hasImageHeightInputTarget) this.imageHeightInputTarget.value = node.attrs.height || ''
        
        this.currentImagePos = selection.from
      }

      this.imagePopoverTarget.style.left = `${start.left}px`
      this.imagePopoverTarget.style.top = `${start.top + 32}px`
      this.imagePopoverTarget.classList.add('hc-image-popover--visible')
    } else {
      this.imagePopoverTarget.classList.remove('hc-image-popover--visible')
    }
  }

  updateAccordionMenu(editor) {
    if (!this.hasAccordionMenuTarget) return
    if (editor.isActive('accordion')) {
      const { view, state } = editor
      const { selection } = state
      const start = view.coordsAtPos(selection.from)
      
      this.accordionMenuTarget.style.left = `${start.left}px`
      this.accordionMenuTarget.style.top = `${start.top - 48}px`
      this.accordionMenuTarget.classList.add('hc-bubble-menu--visible')
    } else {
      this.accordionMenuTarget.classList.remove('hc-bubble-menu--visible')
    }
  }

  updatePlusMenu(editor) {
    if (!this.hasPlusMenuTarget) return

    const { state, view } = editor
    const { selection } = state
    const { $anchor, empty } = selection

    // Only show if selection is empty and in a top-level paragraph block
    if (!empty || $anchor.parent.type.name !== 'paragraph' || $anchor.depth !== 1) {
      this.plusMenuTarget.classList.remove('hc-plus-menu--visible')
      return
    }

    // Only show if the paragraph is empty
    if ($anchor.parent.textContent.length > 0) {
      this.plusMenuTarget.classList.remove('hc-plus-menu--visible')
      return
    }

    const start = view.coordsAtPos($anchor.pos)
    
    // Position 32px to the left of the text cursor
    this.plusMenuTarget.style.left = `${start.left - 32}px`
    // Vertically center it with the text line (approx top - 2px)
    this.plusMenuTarget.style.top = `${start.top - 2}px`
    this.plusMenuTarget.classList.add('hc-plus-menu--visible')
  }

  insertSlashCommand() {
    this.editor.commands.insertContent('/')
    this.editor.view.focus()
  }

  // ─── Auto Save ──────────────────────────────────────────────────────

  scheduleAutoSave() {
    if (this._autoSaveTimer) clearTimeout(this._autoSaveTimer)
    this._autoSaveTimer = setTimeout(() => this.save(), 3000)
  }

  // ─── Save Draft ─────────────────────────────────────────────────────

  async save() {
    if (!this.hasUpdateUrlValue) return // Cannot autosave a new article before it's created
    if (this._saving || !this.isDirty) return
    this._saving = true

    const saveBtn = document.getElementById("ae-save-btn")
    if (saveBtn) {
      saveBtn.disabled = true
      saveBtn.innerHTML = '<span class="hc-btn-spinner"></span> Saving...'
    }

    try {
      const html = this.editor.getHTML()
      const title = this.hasTitleInputTarget ? this.titleInputTarget.value : ''

      const payload = {
        article_locale: this.localeValue,
        article: {
          translations_attributes: {
            0: {
              draft_content: html,
              draft_title: title,
              locale: this.localeValue,
            },
          },
        },
        save_draft: '1',
      }

      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
          "Accept": "application/json",
        },
        body: JSON.stringify(payload),
      })

      const data = await response.json()

      if (data.success) {
        this.isDirty = false
        this.hasUnpublishedChangesValue = true
        this.updateDraftBadge(true)
        this.showToast(data.message || "Draft saved", "success")
      } else {
        this.showToast(data.errors?.join(", ") || "Save failed", "error")
      }
    } catch (err) {
      this.showToast(`Save failed: ${err.message}`, "error")
    } finally {
      this._saving = false
      if (saveBtn) {
        saveBtn.disabled = false
        saveBtn.innerHTML = 'Save Draft'
      }
    }
  }

  // ─── Publish ────────────────────────────────────────────────────────

  async publish() {
    if (!confirm("This will publish the current draft content as the live article. Continue?")) return

    // Save first if dirty
    if (this.isDirty) await this.save()

    const publishBtn = document.getElementById("ae-publish-btn")
    if (publishBtn) {
      publishBtn.disabled = true
      publishBtn.innerHTML = '<span class="hc-btn-spinner"></span> Publishing...'
    }

    try {
      const response = await fetch(this.publishUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify({ article_locale: this.localeValue }),
      })

      const data = await response.json()

      if (data.success) {
        this.hasUnpublishedChangesValue = false
        this.statusValue = 'published'
        this.updateDraftBadge(false)
        this.showToast(data.message || "Published!", "success")
      } else {
        this.showToast(data.errors?.join(", ") || "Publish failed", "error")
      }
    } catch (err) {
      this.showToast(`Publish failed: ${err.message}`, "error")
    } finally {
      if (publishBtn) {
        publishBtn.disabled = false
        publishBtn.innerHTML = 'Publish'
      }
    }
  }

  // ─── Related Articles ────────────────────────────────────────────────

  async updateRelatedArticles(event) {
    const selectedOptions = Array.from(event.target.selectedOptions).map(opt => opt.value)
    
    const payload = {
      article: {
        related_article_ids: selectedOptions
      }
    }

    try {
      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
          "Accept": "application/json",
        },
        body: JSON.stringify(payload),
      })

      const data = await response.json()

      if (data.success) {
        this.showToast("Related articles updated", "success")
      } else {
        this.showToast(data.errors?.join(", ") || "Update failed", "error")
      }
    } catch (err) {
      this.showToast(`Failed to update related articles: ${err.message}`, "error")
    }
  }

  // ─── Discard Draft ──────────────────────────────────────────────────

  async discardDraft() {
    if (!confirm("This will discard all unpublished changes and reset to the last published version. Continue?")) return

    try {
      const response = await fetch(this.discardUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify({ article_locale: this.localeValue }),
      })

      const data = await response.json()

      if (data.success) {
        this.hasUnpublishedChangesValue = false
        this.updateDraftBadge(false)
        this.showToast(data.message || "Draft discarded", "success")
        setTimeout(() => window.location.reload(), 800)
      } else {
        this.showToast(data.errors?.join(", ") || "Discard failed", "error")
      }
    } catch (err) {
      this.showToast(`Discard failed: ${err.message}`, "error")
    }
  }

  // ─── Locale Switching ───────────────────────────────────────────────

  switchLocale(event) {
    event.preventDefault()
    const targetLocale = event.currentTarget.dataset.locale
    if (!targetLocale || targetLocale === this.localeValue) return

    if (this.isDirty) {
      if (!confirm("You have unsaved changes. Switch locale anyway?")) return
    }

    this.navigateToLocale(targetLocale)
  }

  async addLocale(event) {
    event.preventDefault()
    const targetLocale = event.currentTarget.dataset.locale
    if (!targetLocale) return
    
    this.closeAddLocaleMenu()

    try {
      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          article_locale: targetLocale,
          article: {
            translations_attributes: {
              0: {
                locale: targetLocale,
                draft_title: "",
                draft_content: ""
              }
            }
          }
        })
      })

      if (response.ok) {
        this.navigateToLocale(targetLocale)
      } else {
        this.showToast("Failed to add locale", "error")
      }
    } catch (err) {
      this.showToast(`Error adding locale: ${err.message}`, "error")
    }
  }

  navigateToLocale(locale) {
    const url = new URL(this.editUrlValue || window.location.href, window.location.origin)
    url.searchParams.set('article_locale', locale)
    window.location.href = url.toString()
  }

  // ─── Copy Locale ────────────────────────────────────────────────────

  async copyFromLocale(event) {
    event.preventDefault()

    const sourceLocale = event.currentTarget.dataset.sourceLocale
    if (!sourceLocale) return

    this.closeCopyMenu()

    if (!confirm(`Copy content from ${sourceLocale.toUpperCase()} to ${this.localeValue.toUpperCase()}? This will overwrite current draft.`)) return

    try {
      const response = await fetch(this.copyLocaleUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfTokenValue,
        },
        body: JSON.stringify({
          source_locale: sourceLocale,
          target_locale: this.localeValue,
        }),
      })

      const data = await response.json()

      if (data.success) {
        this.showToast(data.message || "Locale copied", "success")
        
        if (data.draft_content !== undefined) {
          this.editor.commands.setContent(data.draft_content || '<p></p>')
        }
        if (this.hasTitleInputTarget && data.draft_title !== undefined) {
          this.titleInputTarget.value = data.draft_title || ""
        }
        
        this.isDirty = true
        this.updateDraftBadge(true)
        this.scheduleAutoSave()
      } else {
        this.showToast(data.errors?.join(", ") || "Copy failed", "error")
      }
    } catch (err) {
      this.showToast(`Copy failed: ${err.message}`, "error")
    }
  }

  // ─── Image Upload (via Attachments model) ───────────────────────────

  openImagePicker() {
    if (this.hasImageInputTarget) this.imageInputTarget.click()
  }

  async insertImages() {
    if (!this.hasImageInputTarget) return

    const files = Array.from(this.imageInputTarget.files || [])
    if (files.length === 0) return

    const supportedImageTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
    const maxSize = 5 * 1024 * 1024 // 5MB

    for (const file of files) {
      if (!supportedImageTypes.includes(file.type)) {
        this.showToast(`Unsupported image format: ${file.name}. Please upload JPG, PNG, GIF, WEBP, or SVG.`, "error")
        continue
      }
      if (file.size > maxSize) {
        this.showToast(`Image too large (max 5MB): ${file.name}`, "error")
        continue
      }
      try {
        const result = await this.uploadFile(file, "image")
        if (result?.data?.[0]?.src) {
          this.editor.chain().focus().setImage({
            src: result.data[0].src,
            alt: result.data[0].alt || file.name,
            title: file.name,
          }).run()
        }
      } catch (err) {
        this.showToast(`Image upload failed: ${err.message}`, "error")
      }
    }

    this.imageInputTarget.value = ""
    this.isDirty = true
    this.scheduleAutoSave()
  }

  // ─── File Upload ────────────────────────────────────────────────────

  openFilePicker() {
    if (this.hasFileInputTarget) this.fileInputTarget.click()
  }

  async insertFile() {
    if (!this.hasFileInputTarget) return

    const files = Array.from(this.fileInputTarget.files || [])
    if (files.length === 0) return

    const supportedExtensions = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.zip', '.txt', '.csv']
    const maxSize = 10 * 1024 * 1024 // 10MB

    for (const file of files) {
      const ext = '.' + file.name.split('.').pop().toLowerCase()
      if (!supportedExtensions.includes(ext)) {
        this.showToast(`Unsupported file type: ${file.name}. Please upload PDF, DOC, XLS, ZIP, TXT, or CSV.`, "error")
        continue
      }
      if (file.size > maxSize) {
        this.showToast(`File too large (max 10MB): ${file.name}`, "error")
        continue
      }
      try {
        const result = await this.uploadFile(file, "file")
        if (result?.data?.[0]) {
          this.editor.chain().focus().setFileAttachment({
            src: result.data[0].src,
            filename: result.data[0].name || file.name,
            filesize: this.formatFileSize(file.size),
            filetype: file.type.split('/').pop().toUpperCase() || ext.replace('.', '').toUpperCase(),
          }).run()
        }
      } catch (err) {
        this.showToast(`File upload failed: ${err.message}`, "error")
      }
    }

    this.fileInputTarget.value = ""
    this.isDirty = true
    this.scheduleAutoSave()
  }

  async uploadFile(file, type = "image") {
    const formData = new FormData()
    formData.append("file", file)
    formData.append("resource_type", "HelpCenter::Article")
    formData.append("resource_id", this.articleIdValue)
    formData.append("attachment_type", type)

    const response = await fetch(this.uploadUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.csrfTokenValue,
      },
      body: formData,
    })

    if (!response.ok) {
      const data = await response.json().catch(() => ({}))
      const errMsg = Array.isArray(data.error) ? data.error.join(", ") : (data.error || "Upload failed")
      throw new Error(errMsg)
    }
    return response.json()
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  // ─── Menu Toggles ──────────────────────────────────────────────────

  toggleLocaleMenu(event) {
    if (event) { event.preventDefault(); event.stopPropagation() }
    if (this.hasLocaleMenuTarget) this.localeMenuTarget.classList.toggle("hc-dropdown--open")
    this.closeCopyMenu()
    this.closeAddLocaleMenu()
  }

  toggleCopyMenu(event) {
    if (event) { event.preventDefault(); event.stopPropagation() }
    if (this.hasCopyMenuTarget) this.copyMenuTarget.classList.toggle("hc-dropdown--open")
    this.closeLocaleMenu()
    this.closeAddLocaleMenu()
  }

  toggleAddLocaleMenu(event) {
    if (event) { event.preventDefault(); event.stopPropagation() }
    if (this.hasAddLocaleMenuTarget) this.addLocaleMenuTarget.classList.toggle("hc-dropdown--open")
    this.closeLocaleMenu()
    this.closeCopyMenu()
  }

  closeLocaleMenu() { this.hasLocaleMenuTarget && this.localeMenuTarget.classList.remove("hc-dropdown--open") }
  closeCopyMenu() { this.hasCopyMenuTarget && this.copyMenuTarget.classList.remove("hc-dropdown--open") }
  closeAddLocaleMenu() { this.hasAddLocaleMenuTarget && this.addLocaleMenuTarget.classList.remove("hc-dropdown--open") }

  _closeMenusOnOutsideClick(event) {
    const menus = ['localeMenu', 'copyMenu', 'addLocaleMenu']
    menus.forEach(name => {
      const target = `${name}Target`
      const hasTarget = `has${name.charAt(0).toUpperCase() + name.slice(1)}Target`
      if (this[hasTarget] && this[target].classList.contains("hc-dropdown--open")) {
        if (!this[target].contains(event.target) && !event.target.closest(`[data-action*="toggle${name.charAt(0).toUpperCase() + name.slice(1)}"]`)) {
          this[target].classList.remove("hc-dropdown--open")
        }
      }
    })
  }

  // ─── Side Panel ─────────────────────────────────────────────────────

  toggleSidePanel(event) {
    if (event) event.preventDefault()
    if (this.hasSidePanelTarget) {
      this.sidePanelTarget.classList.toggle('hc-side-panel--open')
    }
  }

  // ─── Draft Badge ────────────────────────────────────────────────────

  updateDraftBadge(hasChanges) {
    if (!this.hasDraftBadgeTarget) return

    if (hasChanges) {
      this.draftBadgeTarget.textContent = 'Unsaved changes'
      this.draftBadgeTarget.classList.add('hc-draft-badge--dirty')
      this.draftBadgeTarget.classList.remove('hc-draft-badge--saved')
    } else {
      this.draftBadgeTarget.textContent = this.statusValue === 'published' ? 'Published' : 'Draft'
      this.draftBadgeTarget.classList.remove('hc-draft-badge--dirty')
      this.draftBadgeTarget.classList.add('hc-draft-badge--saved')
    }
  }

  // ─── Toast Notifications ────────────────────────────────────────────

  showToast(message, type = "info") {
    const container = this.hasToastContainerTarget
      ? this.toastContainerTarget
      : document.body

    const toast = document.createElement("div")
    toast.className = `hc-toast hc-toast--${type}`
    toast.innerHTML = `
      <span class="hc-toast-icon">${type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ'}</span>
      <span class="hc-toast-message">${message}</span>
    `
    container.appendChild(toast)

    requestAnimationFrame(() => toast.classList.add("hc-toast--visible"))

    setTimeout(() => {
      toast.classList.remove("hc-toast--visible")
      setTimeout(() => toast.remove(), 300)
    }, 3500)
  }
}
