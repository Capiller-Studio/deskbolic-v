import { Node, mergeAttributes } from '@tiptap/core'

/**
 * API Endpoint block — structured display for REST API documentation
 * Shows method badge, path, description, and optional params/body.
 */
const ApiEndpoint = Node.create({
  name: 'apiEndpoint',
  group: 'block',
  atom: true,

  addAttributes() {
    return {
      method: { default: 'GET' },
      path: { default: '/api/v1/resource' },
      description: { default: '' },
      params: { default: '{}' },
    }
  },

  parseHTML() {
    return [{
      tag: 'div[data-api-endpoint]',
      getAttrs: el => ({
        method: el.getAttribute('data-method') || 'GET',
        path: el.getAttribute('data-path') || '',
        description: el.getAttribute('data-description') || '',
        params: el.getAttribute('data-params') || '{}',
      }),
    }]
  },

  renderHTML({ HTMLAttributes }) {
    const { method, path, description, params, ...rest } = HTMLAttributes
    return [
      'div',
      mergeAttributes({
        'data-api-endpoint': '',
        'data-method': method,
        'data-path': path,
        'data-description': description,
        'data-params': params,
        class: 'hc-api-endpoint',
      }, rest),
      ['div', { class: 'hc-api-endpoint-header' },
        ['span', { class: `hc-api-method hc-api-method--${method.toLowerCase()}` }, method],
        ['code', { class: 'hc-api-path' }, path],
      ],
      ...(description ? [['p', { class: 'hc-api-description' }, description]] : []),
    ]
  },

  addCommands() {
    return {
      setApiEndpoint: (attrs = {}) => ({ commands }) => {
        return commands.insertContent({
          type: this.name,
          attrs: { method: 'GET', path: '/api/v1/resource', ...attrs },
        })
      },
    }
  },

  addNodeView() {
    return ({ node, getPos, editor }) => {
      const dom = document.createElement('div')
      dom.classList.add('hc-api-endpoint')
      dom.setAttribute('data-api-endpoint', '')
      dom.contentEditable = 'false'

      const header = document.createElement('div')
      header.classList.add('hc-api-endpoint-header')

      const methodBadge = document.createElement('span')
      methodBadge.classList.add('hc-api-method', `hc-api-method--${node.attrs.method.toLowerCase()}`)
      methodBadge.textContent = node.attrs.method

      const pathCode = document.createElement('code')
      pathCode.classList.add('hc-api-path')
      pathCode.textContent = node.attrs.path

      header.append(methodBadge, pathCode)

      // Editable controls
      const controls = document.createElement('div')
      controls.classList.add('hc-api-endpoint-controls')

      const makeInput = (label, attr, placeholder) => {
        const wrap = document.createElement('div')
        wrap.classList.add('hc-api-control-row')
        const lbl = document.createElement('label')
        lbl.textContent = label
        lbl.classList.add('hc-api-control-label')
        const input = document.createElement('input')
        input.type = 'text'
        input.value = node.attrs[attr]
        input.placeholder = placeholder
        input.classList.add('hc-api-control-input')
        input.addEventListener('input', () => {
          const pos = getPos()
          if (pos != null) {
            editor.chain().focus().command(({ tr }) => {
              tr.setNodeMarkup(pos, undefined, { ...node.attrs, [attr]: input.value })
              return true
            }).run()
          }
        })
        wrap.append(lbl, input)
        return wrap
      }

      const methodSelect = document.createElement('div')
      methodSelect.classList.add('hc-api-control-row')
      const mLabel = document.createElement('label')
      mLabel.textContent = 'Method'
      mLabel.classList.add('hc-api-control-label')
      const mSel = document.createElement('select')
      mSel.classList.add('hc-api-control-input')
      ;['GET', 'POST', 'PUT', 'PATCH', 'DELETE'].forEach(m => {
        const opt = document.createElement('option')
        opt.value = m
        opt.textContent = m
        opt.selected = m === node.attrs.method
        mSel.append(opt)
      })
      mSel.addEventListener('change', () => {
        const pos = getPos()
        if (pos != null) {
          editor.chain().focus().command(({ tr }) => {
            tr.setNodeMarkup(pos, undefined, { ...node.attrs, method: mSel.value })
            return true
          }).run()
        }
      })
      methodSelect.append(mLabel, mSel)

      controls.append(
        methodSelect,
        makeInput('Path', 'path', '/api/v1/resource'),
        makeInput('Description', 'description', 'Describe this endpoint...')
      )

      dom.append(header, controls)

      return {
        dom,
        ignoreMutation: () => true,
        stopEvent: (e) => {
          // Stop all events from propagating to Tiptap if they originate from an input/select
          return ['INPUT', 'SELECT', 'TEXTAREA'].includes(e.target.tagName)
        },
        update(updatedNode) {
          if (updatedNode.type.name !== 'apiEndpoint') return false
          methodBadge.textContent = updatedNode.attrs.method
          methodBadge.className = `hc-api-method hc-api-method--${updatedNode.attrs.method.toLowerCase()}`
          pathCode.textContent = updatedNode.attrs.path
          return true
        },
      }
    }
  },
})

export default ApiEndpoint
