import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import { Editor, Node, mergeAttributes } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Underline from "@tiptap/extension-underline"
import TextAlign from "@tiptap/extension-text-align"

const Image = Node.create({
  name: 'image',

  group: 'block',

  atom: true,

  addAttributes() {
    return {
      src: {
        default: null,
      },
      alt: {
        default: null,
      },
      title: {
        default: null,
      },
    }
  },

  parseHTML() {
    return [
      {
        tag: 'img[src]',
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    return ['img', mergeAttributes(HTMLAttributes)]
  },

  addCommands() {
    return {
      setImage: options => ({ commands }) => {
        return commands.insertContent({
          type: this.name,
          attrs: options,
        })
      },
    }
  },
})

const SVG_ICONS = {
  bold: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 4h8a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6z"/><path d="M6 12h9a4 4 0 0 1 4 4 4 4 0 0 1-4 4H6z"/></svg>`,
  italic: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="4" x2="10" y2="4"/><line x1="14" y1="20" x2="5" y2="20"/><line x1="15" y1="4" x2="9" y2="20"/></svg>`,
  underline: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3v7a6 6 0 0 0 6 6 6 6 0 0 0 6-6V3"/><line x1="4" y1="21" x2="20" y2="21"/></svg>`,
  strike: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.3 4.9c-1.3-.6-3.1-1-5.3-1-3.3 0-5.8 1.4-5.8 4 0 3.4 5.2 4.1 8 4.8 2.2.6 3.8 1.3 3.8 3.2 0 2.1-2.2 3.5-5.5 3.5-2.5 0-4.7-.7-6.2-2"/><line x1="3" y1="12" x2="21" y2="12"/></svg>`,
  unorderedList: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="9" y1="6" x2="21" y2="6"/><line x1="9" y1="12" x2="21" y2="12"/><line x1="9" y1="18" x2="21" y2="18"/><circle cx="4" cy="6" r="1.5" fill="currentColor" stroke="none"/><circle cx="4" cy="12" r="1.5" fill="currentColor" stroke="none"/><circle cx="4" cy="18" r="1.5" fill="currentColor" stroke="none"/></svg>`,
  orderedList: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/><line x1="10" y1="18" x2="21" y2="18"/><path d="M4 6h1v4"/><path d="M4 10h2"/><path d="M6 18H4c0-1 2-2 2-3s-1-1.5-2-1"/></svg>`,
  blockQuote: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21c3 0 7-1 7-8V5c0-1.25-.756-2.017-2-2H4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z"/><path d="M15 21c3 0 7-1 7-8V5c0-1.25-.757-2.017-2-2h-4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2h.75c0 2.25.25 4-2.75 4v3c0 1 0 1 1 1z"/></svg>`,
  codeBlock: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>`,
  textAlignLeft: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="17" y1="10" x2="3" y2="10"/><line x1="21" y1="6" x2="3" y2="6"/><line x1="17" y1="14" x2="3" y2="14"/><line x1="21" y1="18" x2="3" y2="18"/></svg>`,
  textAlignCenter: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="10" x2="6" y2="10"/><line x1="21" y1="6" x2="3" y2="6"/><line x1="18" y1="14" x2="6" y2="14"/><line x1="21" y1="18" x2="3" y2="18"/></svg>`,
  textAlignRight: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="21" y1="10" x2="7" y2="10"/><line x1="21" y1="6" x2="3" y2="6"/><line x1="21" y1="14" x2="7" y2="14"/><line x1="21" y1="18" x2="3" y2="18"/></svg>`,
  image: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>`,
};

export default class extends Controller {
  static targets = ["blockQuote", "bold", "italic", "codeBlock", "unorderedList", "orderedList",
  "editor", "content", "strike", "underLine", "textAlignLeft",
  "textAlignCenter", "textAlignRight", "heading", "imageInput", "imageButton"];

  connect() {
    const masterElement = this.element
    if(!this.hasEditorTarget){
      console.log("We cannot find the editor")
      return
    }
    this._injectIcons()
    this.initEditor(masterElement);
  }

  _injectIcons() {
    if (this.hasBoldTarget) this.boldTarget.innerHTML = SVG_ICONS.bold
    if (this.hasItalicTarget) this.italicTarget.innerHTML = SVG_ICONS.italic
    if (this.hasUnderLineTarget) this.underLineTarget.innerHTML = SVG_ICONS.underline
    if (this.hasStrikeTarget) this.strikeTarget.innerHTML = SVG_ICONS.strike
    if (this.hasUnorderedListTarget) this.unorderedListTarget.innerHTML = SVG_ICONS.unorderedList
    if (this.hasOrderedListTarget) this.orderedListTarget.innerHTML = SVG_ICONS.orderedList
    if (this.hasBlockQuoteTarget) this.blockQuoteTarget.innerHTML = SVG_ICONS.blockQuote
    if (this.hasCodeBlockTarget) this.codeBlockTarget.innerHTML = SVG_ICONS.codeBlock
    if (this.hasTextAlignLeftTarget) this.textAlignLeftTarget.innerHTML = SVG_ICONS.textAlignLeft
    if (this.hasTextAlignCenterTarget) this.textAlignCenterTarget.innerHTML = SVG_ICONS.textAlignCenter
    if (this.hasTextAlignRightTarget) this.textAlignRightTarget.innerHTML = SVG_ICONS.textAlignRight
    if (this.hasImageButtonTarget) this.imageButtonTarget.innerHTML = SVG_ICONS.image
  }

  initEditor(masterElement){
    const textArea = this.contentTarget
    const boldButton = this.boldTarget
    const italicButton = this.italicTarget
    const codeblockButton = this.codeBlockTarget
    const olButton = this.orderedListTarget
    const ulButton = this.unorderedListTarget
    const strikeButton = this.strikeTarget
    const blockquoteButton = this.blockQuoteTarget
    const underlineButton = this.underLineTarget
    const headingButton = this.headingTarget
    const textalignleftButton = this.textAlignLeftTarget
    const textaligncenterButton = this.textAlignCenterTarget
    const textalignrightButton = this.textAlignRightTarget
    const tipTapContent = textArea.value || textArea.innerText || ''
    const editor = new Editor({
      element: this.editorTarget,
      content: tipTapContent,
      extensions: [
        StarterKit.configure({
          heading: { levels: [ 1, 2, 3 ] }
        }),
        Underline,
        Image,
        TextAlign.configure({
          types: ['heading', 'paragraph'],
        })
      ],
      editorProps: {
        attributes: {
          class: 'editor-textarea-style',
        },
      },
      editable: true,
      onSelectionUpdate({ editor }) {
        boldButton.classList.toggle("editor-button-selected", editor.isActive('bold'))
        italicButton.classList.toggle("editor-button-selected", editor.isActive('italic'))
        codeblockButton.classList.toggle("editor-button-selected", editor.isActive('codeBlock'))
        ulButton.classList.toggle("editor-button-selected", editor.isActive('bulletList'))
        olButton.classList.toggle("editor-button-selected", editor.isActive('orderedList'))
        strikeButton.classList.toggle("editor-button-selected", editor.isActive('strike'))
        blockquoteButton.classList.toggle("editor-button-selected", editor.isActive('blockquote'))
        underlineButton.classList.toggle("editor-button-selected", editor.isActive('underline'))
        if(!editor.isActive( 'heading', { level: 1 }) && !editor.isActive( 'heading', { level: 2 }) && !editor.isActive( 'heading', { level: 3 }))
        {
          headingButton.value = '0'
          headingButton.classList.toggle("editor-button-selected", false)
        }
        else if(editor.isActive( 'heading', { level: 1 }))
        {
          headingButton.value = '1'
          headingButton.classList.toggle("editor-button-selected", true)
        }
        else if(editor.isActive( 'heading', { level: 2 }))
        {
          headingButton.value = '2'
          headingButton.classList.toggle("editor-button-selected", true)
        }
        else if(editor.isActive( 'heading', { level: 3 }))
        {
          headingButton.value = '3'
          headingButton.classList.toggle("editor-button-selected", true)
        }
        textalignleftButton.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'left' }))
        textaligncenterButton.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'center' }))
        textalignrightButton.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'right' }))
      },
      onUpdate: this.onUpdate
    });
    masterElement.editor = editor
    this.onUpdate()
  }

  italic(){
    const button = this.italicTarget
    const editor = this.element.editor
    editor.chain().focus().toggleItalic().run()
    if(!editor.isActive('codeBlock'))
    {button.classList.toggle("editor-button-selected", editor.isActive('italic'))}
  }

  heading(){
    const button = this.headingTarget
    const editor = this.element.editor
    if(parseInt(button.value))
    {
      editor.chain().focus().toggleHeading({ level: parseInt(button.value) }).run()
      if(this.textAlignLeftTarget.value !== 'left')
      {
        editor.chain().focus().setTextAlign("left").run()
        this.textAlignCenterTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'center' }))
        this.textAlignRightTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'right' }))
      }
    if(!editor.isActive('codeBlock'))
    {
      this.codeBlockTarget.classList.toggle("editor-button-selected", editor.isActive('codeBlock'))
      button.classList.toggle("editor-button-selected", editor.isActive('heading', { level: parseInt(button.value) }))
    }
    return
    }
    if(editor.isActive('heading', { level: 1 }))
    {editor.chain().focus().toggleHeading({ level: 1 }).run()}
    else if(editor.isActive('heading', { level: 2}))
    {editor.chain().focus().toggleHeading({ level: 2 }).run()}
    button.classList.toggle("editor-button-selected", false)
  }

  textAlignLeft(){

    const button = this.textAlignLeftTarget
    const editor = this.element.editor

    if(!editor.isActive('codeBlock'))
    {
      editor.chain().focus().setTextAlign('left').run()
      button.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'left' }))
      this.textAlignCenterTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'center' }))
      this.textAlignRightTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'right' }))
    }
  }

  textAlignCenter(){

    const button = this.textAlignCenterTarget
    const editor = this.element.editor
    if(!editor.isActive('codeBlock'))
    {
      editor.chain().focus().setTextAlign('center').run()
      button.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'center' }))
      this.textAlignLeftTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'left' }))
      this.textAlignRightTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'right' }))
    }
  }

  textAlignRight(){

    const button = this.textAlignRightTarget
    const editor = this.element.editor
    if(!editor.isActive('codeBlock'))
    {
      editor.chain().focus().setTextAlign('right').run()
      button.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'right' }))
      this.textAlignCenterTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'center' }))
      this.textAlignLeftTarget.classList.toggle("editor-button-selected", editor.isActive({ textAlign: 'left' }))
    }
  }

  bold(){
    const button = this.boldTarget
    const editor = this.element.editor
    editor.chain().focus().toggleBold().run()
    if(!editor.isActive('codeBlock'))
    {button.classList.toggle("editor-button-selected", editor.isActive('bold'))}
  }

  underLine(){
    const button = this.underLineTarget
    const editor = this.element.editor
    editor.chain().focus().toggleUnderline().run()
    if(!editor.isActive('codeBlock'))
    {button.classList.toggle("editor-button-selected", editor.isActive('underline'))}
  }

  codeBlock(){
    const button = this.codeBlockTarget
    const editor = this.element.editor
    editor.chain().focus().toggleCodeBlock().run()
    button.classList.toggle("editor-button-selected", editor.isActive('codeBlock'))
    this.boldTarget.classList.toggle("editor-button-selected", false)
    this.italicTarget.classList.toggle("editor-button-selected", false)
    this.orderedListTarget.classList.toggle("editor-button-selected", false)
    this.unorderedListTarget.classList.toggle("editor-button-selected", false)
    this.strikeTarget.classList.toggle("editor-button-selected", false)
    this.blockQuoteTarget.classList.toggle("editor-button-selected", false)
    this.underLineTarget.classList.toggle("editor-button-selected", false)
    this.headingTarget.classList.toggle("editor-button-selected",false)
    this.headingTarget.value = '0'
  }

  unorderedList(){
    const button = this.unorderedListTarget
    const editor = this.element.editor
    const olButton = this.orderedListTarget
    editor.chain().focus().toggleBulletList().run()
    button.classList.toggle("editor-button-selected", editor.isActive('bulletList'))
    olButton.classList.toggle("editor-button-selected", false)
    if(this.headingTarget.value !== '0')
    {
      this.headingTarget.value = '0'
    }
  }

  blockQuote(){
    const button = this.blockQuoteTarget
    const editor = this.element.editor
    editor.chain().focus().toggleBlockquote().run()
    if(!editor.isActive('codeBlock'))
    {button.classList.toggle("editor-button-selected", editor.isActive('blockquote'))}
  }

  orderedList(){
    const button = this.orderedListTarget
    const editor = this.element.editor
    const ulButton = this.unorderedListTarget
    editor.chain().focus().toggleOrderedList().run()
    button.classList.toggle("editor-button-selected", editor.isActive('orderedList'))
    ulButton.classList.toggle("editor-button-selected", false)
    if(this.headingTarget.value !== '0')
    {
      this.headingTarget.value = '0'
    }
  }

  strike(){
    const button = this.strikeTarget
    const editor = this.element.editor
    editor.chain().focus().toggleStrike().run()
    if(!editor.isActive('codeBlock'))
    {button.classList.toggle("editor-button-selected", editor.isActive('strike'))}
  }

  openImagePicker(event){
    event.preventDefault()
    if(!this.hasImageInputTarget || this.element.editor.isActive('codeBlock')) {
      return
    }

    this.imageInputTarget.click()
  }

  async insertImages(){
    if(!this.hasImageInputTarget) {
      return
    }

    const files = Array.from(this.imageInputTarget.files || []).filter((file) => file.type.startsWith("image/"))

    if(files.length === 0) {
      this.imageInputTarget.value = ""
      return
    }

    this.setImageButtonLoading(true)

    for (const file of files) {
      try {
        const attributes = await this.directUpload(file)
        this.addAttachmentInput(attributes.signed_id)
        this.insertImage(attributes, file)
      } catch (error) {
        console.error("Image upload failed", error)
      }
    }

    this.imageInputTarget.value = ""
    this.setImageButtonLoading(false)
    this.onUpdate()
  }

  directUpload(file){
    return new Promise((resolve, reject) => {
      const upload = new DirectUpload(file, this.imageInputTarget.dataset.directUploadUrl)
      upload.create((error, attributes) => {
        if(error) {
          reject(error)
        } else {
          resolve(attributes)
        }
      })
    })
  }

  addAttachmentInput(signedId){
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = this.imageInputTarget.name
    input.value = signedId
    this.imageInputTarget.insertAdjacentElement("afterend", input)
  }

  insertImage(attributes, file){
    const editor = this.element.editor
    const url = this.blobRedirectUrl(attributes, file)

    editor
      .chain()
      .focus()
      .setImage({
        src: url,
        alt: file.name,
        title: file.name,
      })
      .run()
  }

  blobRedirectUrl(attributes, file){
    const uploadUrl = new URL(this.imageInputTarget.dataset.directUploadUrl, window.location.origin)
    const basePath = uploadUrl.pathname.replace(/\/direct_uploads\/?$/, "")
    const filename = encodeURIComponent(attributes.filename || file.name)

    return `${basePath}/blobs/redirect/${attributes.signed_id}/${filename}`
  }

  setImageButtonLoading(isLoading){
    if(!this.hasImageButtonTarget) {
      return
    }

    this.imageButtonTarget.disabled = isLoading
    this.imageButtonTarget.textContent = isLoading ? "Uploading..." : "Image"
  }

  onUpdate = () => {
    const data = this.element.editor.getHTML();
    this.contentTarget.value = data
  }

  preventEnter(event){
    if (event.key === 'Enter' || event.keyCode === 13) {
      event.preventDefault()
    }
  }

  disconnect() {
    if(this.element.editor) {
      this.element.editor.destroy()
    }
  }
}
