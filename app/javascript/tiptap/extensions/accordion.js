import { Node, mergeAttributes } from '@tiptap/core'

/**
 * Accordion block — collapsible content section
 * Renders as a <details> / <summary> pair.
 */

const AccordionSummary = Node.create({
  name: 'accordionSummary',
  group: 'block',
  content: 'inline*',
  defining: true,
  isolating: true,

  parseHTML() {
    return [{ tag: 'summary' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['summary', mergeAttributes({ class: 'hc-accordion-summary' }, HTMLAttributes), 0]
  },
})

const AccordionContent = Node.create({
  name: 'accordionContent',
  group: 'block',
  content: 'block+',
  defining: true,

  parseHTML() {
    return [{ tag: 'div[data-accordion-content]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ 'data-accordion-content': '', class: 'hc-accordion-content' }, HTMLAttributes), 0]
  },
})

const Accordion = Node.create({
  name: 'accordion',
  group: 'block',
  content: 'accordionSummary accordionContent',
  defining: true,

  addAttributes() {
    return {
      open: {
        default: true,
        parseHTML: el => el.hasAttribute('open'),
        renderHTML: attrs => attrs.open ? { open: '' } : {},
      },
    }
  },

  parseHTML() {
    return [{ tag: 'details[data-accordion]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['details', mergeAttributes({ 'data-accordion': '', class: 'hc-accordion' }, HTMLAttributes), 0]
  },

  addCommands() {
    return {
      setAccordion: () => ({ commands }) => {
        return commands.insertContent({
          type: this.name,
          attrs: { open: true },
          content: [
            { type: 'accordionSummary', content: [{ type: 'text', text: 'Click to expand' }] },
            { type: 'accordionContent', content: [{ type: 'paragraph' }] },
          ],
        })
      },
    }
  },
})

export { Accordion, AccordionSummary, AccordionContent }
export default Accordion
