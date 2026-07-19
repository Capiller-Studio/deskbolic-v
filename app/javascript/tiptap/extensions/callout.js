import { Node, mergeAttributes } from '@tiptap/core'

/**
 * Callout block — Info, Warning, Success, General
 * Renders as a styled div with an icon and editable content.
 */
const Callout = Node.create({
  name: 'callout',
  group: 'block',
  content: 'block+',
  defining: true,

  addAttributes() {
    return {
      type: {
        default: 'info',
        parseHTML: el => el.getAttribute('data-callout-type') || 'info',
        renderHTML: attrs => ({ 'data-callout-type': attrs.type }),
      },
    }
  },

  parseHTML() {
    return [{ tag: 'div[data-callout-type]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ class: 'hc-callout' }, HTMLAttributes), ['div', { class: 'hc-callout-content' }, 0]]
  },

  addCommands() {
    return {
      setCallout: (type = 'info') => ({ commands }) => {
        return commands.insertContent({
          type: this.name,
          attrs: { type },
          content: [{ type: 'paragraph' }],
        })
      },
    }
  },
})

export default Callout
