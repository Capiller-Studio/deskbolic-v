import { Controller } from "@hotwired/stimulus"
import { createEditor, $getRoot, $createParagraphNode, $createTextNode, $getSelection, $isRangeSelection, FORMAT_TEXT_COMMAND, UNDO_COMMAND, REDO_COMMAND, KEY_ENTER_COMMAND, COMMAND_PRIORITY_HIGH, INSERT_PARAGRAPH_COMMAND } from 'lexical'
import { registerRichText } from '@lexical/rich-text'
import { registerHistory, createEmptyHistoryState } from '@lexical/history'
import { $generateHtmlFromNodes } from '@lexical/html'
import { registerList, $insertList, INSERT_UNORDERED_LIST_COMMAND, INSERT_ORDERED_LIST_COMMAND, REMOVE_LIST_COMMAND } from '@lexical/list'
import { registerLink } from '@lexical/link'
import { registerMarkdownShortcuts, TRANSFORMERS } from '@lexical/markdown'
import { HeadingNode, QuoteNode } from "@lexical/rich-text";
import { TableNode, TableCellNode, TableRowNode } from "@lexical/table";
import { ListItemNode, ListNode } from "@lexical/list";
import { CodeHighlightNode, CodeNode } from "@lexical/code";
import { AutoLinkNode, LinkNode } from "@lexical/link";
export default class extends Controller {
  static targets = ["editor", "toolbar", "hiddenInput", "boldBtn", "italicBtn", "strikeBtn", "codeBtn", "ulBtn", "olBtn"]
  static values = { source: String, supportedFormats: Array }

  connect() {
    this.initLexical()
    this.buildToolbar()
  }

  initLexical() {
    this.editor = createEditor({
      namespace: 'DeskbolicEditor',
      onError: (error) => console.error('[Lexical]', error),
      nodes: [
        HeadingNode,
        QuoteNode,
        TableNode,
        TableCellNode,
        TableRowNode,
        ListItemNode,
        ListNode,
        CodeHighlightNode,
        CodeNode,
        AutoLinkNode,
        LinkNode
      ],
      editable: true,
      theme: {
        code: 'lexical-code-block',
        text: {
          bold: 'lexical-bold',
          italic: 'lexical-italic',
          strikethrough: 'lexical-strikethrough',
          code: 'lexical-code'
        }
      }
      // theme: {
      //   paragraph: 'lexical-paragraph',
      //   text: {
      //     bold: 'lexical-bold',
      //     italic: 'lexical-italic',
      //     strikethrough: 'lexical-strikethrough',
      //     code: 'lexical-code'
      //   },
      //   list: {
      //     ul: 'lexical-ul',
      //     ol: 'lexical-ol',
      //     listitem: 'lexical-listitem',
      //     nested: {
      //       listitem: 'lexical-nested-listitem'
      //     },
      //     olDepth: [
      //       'lexical-ol1',
      //       'lexical-ol2',
      //       'lexical-ol3',
      //       'lexical-ol4',
      //       'lexical-ol5'
      //     ]
      //   }
      // }
    })

    this.editor.setRootElement(this.editorTarget)
    this.deregisterRichText = registerRichText(this.editor)
    this.deregisterHistory = registerHistory(this.editor, createEmptyHistoryState(), 300)
    this.deregisterList = registerList(this.editor)
    
    let activeTransformers = TRANSFORMERS;
    if (this.hasSupportedFormatsValue) {
      const formats = this.supportedFormatsValue;
      activeTransformers = TRANSFORMERS.filter(transformer => {
        if (transformer.type === 'text-format') {
          return transformer.format.every(f => formats.includes(f));
        }
        if (transformer.type === 'element' || transformer.type === 'multiline-element' || transformer.type === 'text-match') {
          const hasDep = (name) => transformer.dependencies && transformer.dependencies.some(d => d.name === name);
          
          if (hasDep('CodeNode')) return formats.includes('code');
          if (hasDep('ListNode') || hasDep('ListItemNode')) return formats.includes('ul') || formats.includes('ol');
          if (hasDep('QuoteNode')) return formats.includes('quote');
          if (hasDep('HeadingNode')) return formats.includes('heading');
          if (hasDep('LinkNode')) return formats.includes('link');
        }
        return false;
      });
    }
    
    this.deregisterMarkdown = registerMarkdownShortcuts(this.editor, activeTransformers)
    // Removed registerLink(this.editor) as it crashes in this version of Lexical without stores config
    
    if (this.hasSupportedFormatsValue) {
      const formats = this.supportedFormatsValue;
      const formatMap = { bold: 'bold', italic: 'italic', strike: 'strikethrough', code: 'code', ul: 'ul', ol: 'ol' };
      
      this.element.querySelectorAll('.format-btn').forEach(btn => {
        const targetAttr = btn.dataset.lexicalTarget;
        if (!targetAttr) return;
        
        const key = targetAttr.replace('Btn', '');
        const requiredFormat = formatMap[key];
        
        if (requiredFormat && !formats.includes(requiredFormat)) {
          btn.style.display = 'none';
        }
      });
    }

    // Sync state to hidden input
    this.editor.registerUpdateListener(({ editorState }) => {
      editorState.read(() => {
        const root = $getRoot()
        let isEmpty = false
        if (root.getChildrenSize() === 0) {
          isEmpty = true
        } else if (root.getChildrenSize() === 1) {
          const firstChild = root.getFirstChild()
          if (firstChild.getType() === 'paragraph' && firstChild.getTextContent().trim().length === 0) {
            isEmpty = true
          }
        }
        
        if(isEmpty) {
          this.editorTarget.classList.add('lexical-empty')
          if (this.hasHiddenInputTarget) {
            this.hiddenInputTarget.value = ""
          }
        } else {
          this.editorTarget.classList.remove('lexical-empty')
          if (this.hasHiddenInputTarget) {
            try {
              this.hiddenInputTarget.value = $generateHtmlFromNodes(this.editor, null)
            } catch (e) {
              console.error("[Lexical HTML Generation Error]", e)
              this.hiddenInputTarget.value = this.editorTarget.innerHTML
            }
          }
        }
        
        // Inside read() we can also update the toolbar based on selection
        this.updateToolbar()
      })
    })

    // Initial empty check
    this.editor.getEditorState().read(() => {
      const root = $getRoot()
      let isEmpty = false
      if (root.getChildrenSize() === 0) {
        isEmpty = true
      } else if (root.getChildrenSize() === 1) {
        const firstChild = root.getFirstChild()
        if (firstChild.getType() === 'paragraph' && firstChild.getTextContent().trim().length === 0) {
          isEmpty = true
        }
      }
      if(isEmpty) {
        this.editorTarget.classList.add('lexical-empty')
      }
    })

    // Handle enter to submit vs shift+enter for new line/list split
    this.editor.registerCommand(
      KEY_ENTER_COMMAND,
      (event) => {
        if (event && event.shiftKey) {
          // Allow shift+enter for new line/list splitting
          event.preventDefault()
          this.editor.dispatchCommand(INSERT_PARAGRAPH_COMMAND, undefined)
          return true
        }
        
        if (event) {
          event.preventDefault()
        }
        if (this.hasEditorTarget && this.hasHiddenInputTarget) {
          try {
            this.editor.getEditorState().read(() => {
              this.hiddenInputTarget.value = $generateHtmlFromNodes(this.editor, null)
            })
          } catch(e) {
            this.hiddenInputTarget.value = this.editorTarget.innerHTML
          }
        }
        
        const form = this.element.closest('form')
        if (form) {
          const submitBtn = form.querySelector('[type="submit"]')
          if (submitBtn) {
            form.requestSubmit(submitBtn)
          } else {
            form.requestSubmit()
          }
        }
        return true
      },
      COMMAND_PRIORITY_HIGH
    )

    // Wait for the closest form to submit and clear
    const form = this.element.closest('form')
    if(form) {
      form.addEventListener('turbo:submit-end', (e) => {
        if(e.detail.success) {
          this.clear()
        }
      })
    }
  }

  buildToolbar() {
    const source = this.sourceValue || "email"
    
    // SMS supports no formatting
    if (source === "sms") {
      if(this.hasToolbarTarget) this.toolbarTarget.style.display = "none"
      return
    }

    // WhatsApp supports limited formatting
    if (source === "whatsapp" || source === "facebook") {
      if(this.hasUlBtnTarget) this.ulBtnTarget.style.display = 'none'
      if(this.hasOlBtnTarget) this.olBtnTarget.style.display = 'none'
    }
  }

  updateToolbar() {
    const selection = $getSelection()
    if ($isRangeSelection(selection)) {
      if(this.hasBoldBtnTarget) this.boldBtnTarget.classList.toggle('active', selection.hasFormat('bold'))
      if(this.hasItalicBtnTarget) this.italicBtnTarget.classList.toggle('active', selection.hasFormat('italic'))
      if(this.hasStrikeBtnTarget) this.strikeBtnTarget.classList.toggle('active', selection.hasFormat('strikethrough'))
      if(this.hasCodeBtnTarget) this.codeBtnTarget.classList.toggle('active', selection.hasFormat('code'))
      
      let isUl = false;
      let isOl = false;
      
      const anchorNode = selection.anchor.getNode();
      let node = anchorNode;
      while (node && node.getKey() !== 'root') {
        if (node.getType && node.getType() === 'list') {
          if (node.getListType() === 'bullet') isUl = true;
          if (node.getListType() === 'number') isOl = true;
          break;
        }
        node = node.getParent ? node.getParent() : null;
      }
      
      if(this.hasUlBtnTarget) this.ulBtnTarget.classList.toggle('active', isUl);
      if(this.hasOlBtnTarget) this.olBtnTarget.classList.toggle('active', isOl);
    }
  }

  formatBold(e) {
    e.preventDefault()
    this.editor.focus()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'bold')
  }

  formatItalic(e) {
    e.preventDefault()
    this.editor.focus()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'italic')
  }

  formatStrike(e) {
    e.preventDefault()
    this.editor.focus()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'strikethrough')
  }

  formatCode(e) {
    e.preventDefault()
    this.editor.focus()
    this.editor.dispatchCommand(FORMAT_TEXT_COMMAND, 'code')
  }

  formatBulletList(e) {
    e.preventDefault()
    this.editor.focus()
    if (this.hasUlBtnTarget && this.ulBtnTarget.classList.contains('active')) {
      this.editor.dispatchCommand(REMOVE_LIST_COMMAND, undefined)
    } else {
      this.editor.dispatchCommand(INSERT_UNORDERED_LIST_COMMAND, undefined)
    }
  }

  formatNumberedList(e) {
    e.preventDefault()
    this.editor.focus()
    if (this.hasOlBtnTarget && this.olBtnTarget.classList.contains('active')) {
      this.editor.dispatchCommand(REMOVE_LIST_COMMAND, undefined)
    } else {
      this.editor.dispatchCommand(INSERT_ORDERED_LIST_COMMAND, undefined)
    }
  }

  // Public method for external controllers (Emoji / Mentions) to insert text
  insertText(text) {
    this.editor.update(() => {
      let selection = $getSelection()
      
      if (!selection) {
        const root = $getRoot()
        if (root.isEmpty()) {
          const paragraph = $createParagraphNode()
          paragraph.append($createTextNode(text))
          root.append(paragraph)
          paragraph.selectEnd()
          return
        } else {
          selection = root.selectEnd()
        }
      }
      
      if (selection) {
        selection.insertText(text)
      }
    })
  }

  replaceText(deleteBackwardsCount, text) {
    this.editor.focus()
    this.editor.update(() => {
      const selection = $getSelection()
      if ($isRangeSelection(selection) && selection.isCollapsed()) {
        const anchor = selection.anchor
        const currentOffset = anchor.offset
        if (currentOffset >= deleteBackwardsCount) {
          anchor.set(anchor.key, currentOffset - deleteBackwardsCount, 'text')
          selection.insertText(text)
        } else {
          // If it crosses node boundaries, just fallback to replacing the node's text
          const textNode = anchor.getNode()
          const content = textNode.getTextContent()
          const newContent = content.substring(0, currentOffset - deleteBackwardsCount) + text + content.substring(currentOffset)
          textNode.setTextContent(newContent)
          // Move cursor to end of inserted text
          textNode.select(currentOffset - deleteBackwardsCount + text.length)
        }
      }
    })
  }

  clear() {
    this.editor.update(() => {
      const root = $getRoot()
      root.clear()
      const p = $createParagraphNode()
      root.append(p)
    })
  }

  getText() {
    let text = ""
    this.editor.getEditorState().read(() => {
      text = $getRoot().getTextContent()
    })
    return text
  }

  disconnect() {
    if (this.deregisterRichText) this.deregisterRichText()
    if (this.deregisterHistory) this.deregisterHistory()
    this.editor = null
  }
}
