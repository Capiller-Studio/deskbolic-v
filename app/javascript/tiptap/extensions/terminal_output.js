import { Node, mergeAttributes } from '@tiptap/core'

/**
 * Terminal Output block — styled terminal/console output display
 * Non-editable pre/code block with a terminal header.
 */
const TerminalOutput = Node.create({
  name: 'terminalOutput',
  group: 'block',
  content: 'text*',
  marks: '',
  code: true,
  defining: true,

  addAttributes() {
    return {
      title: {
        default: 'Terminal',
        parseHTML: el => el.getAttribute('data-terminal-title') || 'Terminal',
        renderHTML: attrs => ({ 'data-terminal-title': attrs.title }),
      },
    }
  },

  parseHTML() {
    return [{ tag: 'div[data-terminal-output]' }]
  },

  renderHTML({ HTMLAttributes }) {
    const { title, ...rest } = HTMLAttributes
    return [
      'div',
      mergeAttributes({ 'data-terminal-output': '', class: 'hc-terminal-output' }, rest),
      ['div', { class: 'hc-terminal-header' },
        ['span', { class: 'hc-terminal-dot hc-terminal-dot--red' }],
        ['span', { class: 'hc-terminal-dot hc-terminal-dot--yellow' }],
        ['span', { class: 'hc-terminal-dot hc-terminal-dot--green' }],
        ['span', { class: 'hc-terminal-title' }, title || 'Terminal'],
      ],
      ['pre', { class: 'hc-terminal-body' }, ['code', 0]],
    ]
  },

  addCommands() {
    return {
      setTerminalOutput: (attrs = {}) => ({ commands }) => {
        return commands.insertContent({
          type: this.name,
          attrs: { title: 'Terminal', ...attrs },
          content: [{ type: 'text', text: '$ ' }],
        })
      },
    }
  },
})

export default TerminalOutput
