import { Extension } from '@tiptap/core'
import Suggestion from '@tiptap/suggestion'
import { PluginKey } from '@tiptap/pm/state'

/**
 * SlashCommands — type "/" to open a block inserter menu
 * Shows categorized block types that can be inserted at the cursor position.
 */

const SLASH_COMMANDS_KEY = new PluginKey('slashCommands')

// Block type definitions organized by category
export const SLASH_MENU_ITEMS = [
  {
    category: 'Text',
    items: [
      { title: 'Heading 1', description: 'Large section heading', icon: 'H1', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setNode('heading', { level: 1 }).run() } },
      { title: 'Heading 2', description: 'Medium heading', icon: 'H2', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setNode('heading', { level: 2 }).run() } },
      { title: 'Heading 3', description: 'Small heading', icon: 'H3', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setNode('heading', { level: 3 }).run() } },
      { title: 'Paragraph', description: 'Plain text block', icon: '¶', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setNode('paragraph').run() } },
    ],
  },
  {
    category: 'Lists',
    items: [
      { title: 'Bullet List', description: 'Unordered list', icon: '•', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).toggleBulletList().run() } },
      { title: 'Numbered List', description: 'Ordered list', icon: '1.', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).toggleOrderedList().run() } },
    ],
  },
  {
    category: 'Rich Content',
    items: [
      { title: 'Blockquote', description: 'Quote or excerpt', icon: '"', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).toggleBlockquote().run() } },
      { title: 'Code Block', description: 'Syntax-highlighted code', icon: '<>', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).toggleCodeBlock().run() } },
      { title: 'Horizontal Rule', description: 'Visual separator', icon: '—', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setHorizontalRule().run() } },
      { title: 'Image', description: 'Upload an image', icon: '🖼', command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).run()
        // Trigger the file input from the article editor controller
        const fileInput = document.querySelector('[data-help-center--article-editor-target="imageInput"]')
        if (fileInput) fileInput.click()
      }},
    ],
  },
  {
    category: 'Tables',
    items: [
      { title: 'Table', description: 'Insert a table', icon: '⊞', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run() } },
    ],
  },
  {
    category: 'Callouts',
    items: [
      { title: 'Info Callout', description: 'Blue info box', icon: 'ℹ', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setCallout('info').run() } },
      { title: 'Warning Callout', description: 'Yellow warning box', icon: '⚠', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setCallout('warning').run() } },
      { title: 'Success Callout', description: 'Green success box', icon: '✓', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setCallout('success').run() } },
      { title: 'Danger Callout', description: 'Red danger box', icon: '✕', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setCallout('danger').run() } },
    ],
  },
  {
    category: 'Advanced',
    items: [
      { title: 'Accordion', description: 'Collapsible section', icon: '▸', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setAccordion().run() } },
      { title: 'Button', description: 'Call-to-action button', icon: '⏩', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setButtonBlock().run() } },
      { title: 'Terminal Output', description: 'Console/terminal display', icon: '▶', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setTerminalOutput().run() } },
      { title: 'API Endpoint', description: 'REST API reference block', icon: '⚡', command: ({ editor, range }) => { editor.chain().focus().deleteRange(range).setApiEndpoint().run() } },
      { title: 'File Attachment', description: 'Downloadable file card', icon: '📎', command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).run()
        const fileInput = document.querySelector('[data-help-center--article-editor-target="fileInput"]')
        if (fileInput) fileInput.click()
      }},
      { title: 'YouTube Video', description: 'Embed a YouTube video', icon: '▶️', command: ({ editor, range }) => {
        editor.chain().focus().deleteRange(range).run()
        const { view, state } = editor
        const start = view.coordsAtPos(state.selection.from)
        const event = new CustomEvent('article-editor:open-youtube', { detail: { coords: start } })
        window.dispatchEvent(event)
      }},
    ],
  },
]

function getFilteredItems(query) {
  const search = (query || '').toLowerCase()
  return SLASH_MENU_ITEMS.map(group => ({
    ...group,
    items: group.items.filter(item =>
      item.title.toLowerCase().includes(search) ||
      item.description.toLowerCase().includes(search)
    ),
  })).filter(group => group.items.length > 0)
}

// Render the slash menu popup
function renderSlashMenu(element, props) {
  const { items: filteredGroups, command } = props
  element.innerHTML = ''
  element.className = 'hc-slash-menu'

  if (filteredGroups.length === 0) {
    const empty = document.createElement('div')
    empty.className = 'hc-slash-menu-empty'
    empty.textContent = 'No results'
    element.appendChild(empty)
    return
  }

  let allItems = []
  filteredGroups.forEach(group => {
    const label = document.createElement('div')
    label.className = 'hc-slash-menu-label'
    label.textContent = group.category
    element.appendChild(label)

    group.items.forEach(item => {
      const btn = document.createElement('button')
      btn.className = 'hc-slash-menu-item'
      btn.type = 'button'
      btn.innerHTML = `
        <span class="hc-slash-menu-icon">${item.icon}</span>
        <span class="hc-slash-menu-text">
          <span class="hc-slash-menu-title">${item.title}</span>
          <span class="hc-slash-menu-desc">${item.description}</span>
        </span>
      `
      btn.addEventListener('click', () => command(item))
      element.appendChild(btn)
      allItems.push({ btn, item })
    })
  })

  // Keyboard navigation
  let selectedIndex = 0
  const selectItem = (index) => {
    allItems.forEach((entry, i) => {
      entry.btn.classList.toggle('hc-slash-menu-item--selected', i === index)
    })
    selectedIndex = index
    allItems[index]?.btn.scrollIntoView({ block: 'nearest' })
  }
  selectItem(0)

  element._onKeyDown = (event) => {
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      selectItem((selectedIndex + 1) % allItems.length)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      selectItem((selectedIndex - 1 + allItems.length) % allItems.length)
    } else if (event.key === 'Enter') {
      event.preventDefault()
      if (allItems[selectedIndex]) command(allItems[selectedIndex].item)
    }
  }
}

const SlashCommands = Extension.create({
  name: 'slashCommands',

  addProseMirrorPlugins() {
    let popup = null

    return [
      Suggestion({
        editor: this.editor,
        pluginKey: SLASH_COMMANDS_KEY,
        char: '/',
        startOfLine: false,
        command: ({ editor, range, props }) => {
          props.command({ editor, range })
        },
        items: ({ query }) => getFilteredItems(query),
        render: () => {
          let element = null

          return {
            onStart: (props) => {
              element = document.createElement('div')
              document.body.appendChild(element)

              renderSlashMenu(element, {
                items: props.items,
                command: (item) => {
                  item.command({ editor: props.editor, range: props.range })
                  if (element) {
                    element.remove()
                    element = null
                  }
                },
              })

              // Position near cursor
              const { view } = props.editor
              const coords = view.coordsAtPos(props.range.from)
              element.style.position = 'fixed'
              element.style.top = `${coords.bottom + 8}px`
              element.style.left = `${coords.left}px`
              element.style.zIndex = '9999'

              // Add keyboard handler
              if (element._onKeyDown) {
                view.dom.addEventListener('keydown', element._onKeyDown)
              }
            },
            onUpdate: (props) => {
              if (!element) return

              // Re-render with new filter
              const { view } = props.editor

              if (element._onKeyDown) {
                view.dom.removeEventListener('keydown', element._onKeyDown)
              }

              renderSlashMenu(element, {
                items: props.items,
                command: (item) => {
                  item.command({ editor: props.editor, range: props.range })
                  if (element) {
                    element.remove()
                    element = null
                  }
                },
              })

              // Reposition
              const coords = view.coordsAtPos(props.range.from)
              element.style.top = `${coords.bottom + 8}px`
              element.style.left = `${coords.left}px`

              if (element._onKeyDown) {
                view.dom.addEventListener('keydown', element._onKeyDown)
              }
            },
            onKeyDown: (props) => {
              if (props.event.key === 'Escape') {
                if (element) {
                  const { view } = props.editor
                  if (element._onKeyDown) {
                    view.dom.removeEventListener('keydown', element._onKeyDown)
                  }
                  element.remove()
                  element = null
                }
                return true
              }
              // Let the _onKeyDown handler deal with arrow/enter
              if (['ArrowDown', 'ArrowUp', 'Enter'].includes(props.event.key)) {
                return true
              }
              return false
            },
            onExit: (props) => {
              if (element) {
                const { view } = props.editor
                if (element._onKeyDown) {
                  view.dom.removeEventListener('keydown', element._onKeyDown)
                }
                element.remove()
                element = null
              }
            },
          }
        },
      }),
    ]
  },
})

export default SlashCommands
