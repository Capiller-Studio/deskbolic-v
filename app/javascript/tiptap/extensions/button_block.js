import { Node, mergeAttributes } from '@tiptap/core'

/**
 * Button CTA block — styled clickable button
 */
const ButtonBlock = Node.create({
  name: 'buttonBlock',
  group: 'block',
  atom: true,

  addAttributes() {
    return {
      label: { default: 'Click me' },
      href: { default: '#' },
      variant: { default: 'primary' }, // primary | secondary | outline
      align: { default: 'left' },     // left | center | right
    }
  },

  parseHTML() {
    return [{
      tag: 'div[data-button-block]',
      getAttrs: el => ({
        label: el.querySelector('a')?.textContent || 'Click me',
        href: el.querySelector('a')?.getAttribute('href') || '#',
        variant: el.getAttribute('data-variant') || 'primary',
        align: el.getAttribute('data-align') || 'left',
      }),
    }]
  },

  renderHTML({ HTMLAttributes }) {
    const { label, href, variant, align, ...rest } = HTMLAttributes
    return [
      'div',
      mergeAttributes({
        'data-button-block': '',
        'data-variant': variant,
        'data-align': align,
        class: 'hc-button-block',
        style: `text-align: ${align}`,
      }, rest),
      ['a', { href, class: `hc-cta-btn hc-cta-btn--${variant}`, target: '_blank', rel: 'noopener' }, label],
    ]
  },

  addCommands() {
    return {
      setButtonBlock: (attrs = {}) => ({ commands }) => {
        return commands.insertContent({
          type: this.name,
          attrs: { label: 'Click me', href: '#', variant: 'primary', align: 'left', ...attrs },
        })
      },
    }
  },

  addNodeView() {
    return ({ node, getPos, editor }) => {
      const dom = document.createElement('div')
      dom.classList.add('hc-button-block')
      dom.setAttribute('data-button-block', '')
      dom.style.textAlign = node.attrs.align
      dom.contentEditable = 'false'

      const btn = document.createElement('span')
      btn.classList.add('hc-cta-btn', `hc-cta-btn--${node.attrs.variant}`)
      btn.textContent = node.attrs.label
      btn.contentEditable = 'false'

      const controls = document.createElement('div')
      controls.classList.add('hc-button-block-controls')
      controls.contentEditable = 'false'

      // Label input
      const labelInput = document.createElement('input')
      labelInput.type = 'text'
      labelInput.value = node.attrs.label
      labelInput.placeholder = 'Button text'
      labelInput.classList.add('hc-button-block-input')
      labelInput.addEventListener('input', () => {
        const pos = getPos()
        if (pos != null) {
          editor.chain().focus().command(({ tr }) => {
            tr.setNodeMarkup(pos, undefined, { ...node.attrs, label: labelInput.value })
            return true
          }).run()
        }
      })

      // URL input
      const urlInput = document.createElement('input')
      urlInput.type = 'text'
      urlInput.value = node.attrs.href
      urlInput.placeholder = 'https://...'
      urlInput.classList.add('hc-button-block-input')
      urlInput.addEventListener('input', () => {
        const pos = getPos()
        if (pos != null) {
          editor.chain().focus().command(({ tr }) => {
            tr.setNodeMarkup(pos, undefined, { ...node.attrs, href: urlInput.value })
            return true
          }).run()
        }
      })

      controls.append(labelInput, urlInput)
      dom.append(btn, controls)

      return {
        dom,
        update(updatedNode) {
          if (updatedNode.type.name !== 'buttonBlock') return false
          btn.textContent = updatedNode.attrs.label
          btn.className = `hc-cta-btn hc-cta-btn--${updatedNode.attrs.variant}`
          dom.style.textAlign = updatedNode.attrs.align
          return true
        },
      }
    }
  },
})

export default ButtonBlock
