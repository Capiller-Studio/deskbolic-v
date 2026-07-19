import { Mark, mergeAttributes } from '@tiptap/core'

/**
 * Keyboard Shortcut mark — renders as <kbd> elements
 * Inline mark, not a block. Applied like bold/italic.
 */
const KeyboardShortcut = Mark.create({
  name: 'kbd',

  parseHTML() {
    return [{ tag: 'kbd' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['kbd', mergeAttributes({ class: 'hc-kbd' }, HTMLAttributes), 0]
  },

  addCommands() {
    return {
      toggleKbd: () => ({ commands }) => {
        return commands.toggleMark(this.name)
      },
    }
  },

  addKeyboardShortcuts() {
    return {
      'Mod-Shift-k': () => this.editor.commands.toggleKbd(),
    }
  },
})

export default KeyboardShortcut
