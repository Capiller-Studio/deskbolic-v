import { Node, mergeAttributes } from '@tiptap/core'

/**
 * File Attachment block — renders as a styled download card
 * Uses the Attachments controller for upload/storage.
 */
const FileAttachment = Node.create({
  name: 'fileAttachment',
  group: 'block',
  atom: true,

  addAttributes() {
    return {
      src: { default: null },
      filename: { default: 'Untitled file' },
      filesize: { default: '' },
      filetype: { default: '' },
    }
  },

  parseHTML() {
    return [{
      tag: 'div[data-file-attachment]',
      getAttrs: el => ({
        src: el.getAttribute('data-src'),
        filename: el.getAttribute('data-filename'),
        filesize: el.getAttribute('data-filesize'),
        filetype: el.getAttribute('data-filetype'),
      }),
    }]
  },

  renderHTML({ HTMLAttributes }) {
    const { src, filename, filesize, filetype, ...rest } = HTMLAttributes
    return [
      'div',
      mergeAttributes({
        'data-file-attachment': '',
        'data-src': src,
        'data-filename': filename,
        'data-filesize': filesize,
        'data-filetype': filetype,
        class: 'hc-file-attachment',
      }, rest),
      ['div', { class: 'hc-file-attachment-icon' }, '📎'],
      ['div', { class: 'hc-file-attachment-info' },
        ['span', { class: 'hc-file-attachment-name' }, filename || 'Untitled file'],
        ['span', { class: 'hc-file-attachment-meta' }, [filesize, filetype].filter(Boolean).join(' · ')],
      ],
      ['a', { href: src, download: filename, class: 'hc-file-attachment-download', target: '_blank' }, 'Download'],
    ]
  },

  addCommands() {
    return {
      setFileAttachment: (attrs = {}) => ({ commands }) => {
        return commands.insertContent({
          type: this.name,
          attrs,
        })
      },
    }
  },
})

export default FileAttachment
