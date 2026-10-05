import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    summarizeUrl: String,
    draftUrl: String,
    rewriteUrl: String,
    grammarUrl: String,
    translateUrl: String,
    generatingSummary: String,
    summaryHeading: String,
    draftingReply: String,
    errorPrefix: String,
    creditsExhausted: String
  }
  static targets = ["instruction"]
  static outlets = ["lexical"]

  async postData(url, bodyData = null) {
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    };
    if (bodyData) {
      options.body = JSON.stringify(bodyData);
    }
    return await fetch(url, options);
  }

  async summarize(e) {
    e.preventDefault()
    const btn = e.currentTarget
    this.disableButton(btn)

    try {
      const response = await this.postData(this.summarizeUrlValue)
      const data = await response.json()

      if (data.success) {
        // The backend created a private note with the summary. 
        // ActionCable will broadcast it automatically.
      } else {
        alert(data.error)
      }
    } catch (error) {
      console.error("AI Summarize error:", error)
      alert("Failed to connect to AI service.")
    } finally {
      this.enableButton(btn)
    }
  }

  async draftReply(e) {
    e.preventDefault()
    
    const instruction = this.instructionTarget.value
    if (!instruction) return
    
    const btn = e.currentTarget
    this.disableButton(btn)
    
    this.instructionTarget.value = "" // clear input
    // this.insertIntoEditor(`🤖 ${this.draftingReplyValue || "Drafting reply..."}`)

    try {
      const response = await this.postData(this.draftUrlValue, { instruction: instruction })
      const data = await response.json()
      
      if (data.success) {
        const draftText = (data.draft || "").trim()
        const currentText = (this.getCurrentText() || "").trim()
        if (currentText.length === 0) {
          if (this.hasLexicalOutlet) {
            this.lexicalOutlet.clear()
            this.lexicalOutlet.insertText(draftText)
          } else {
            this.insertIntoEditor(draftText)
          }
        } else {
          this.insertIntoEditor(`\n${draftText}`)
        }
      } else {
        this.insertIntoEditor(`\n${this.errorPrefixValue || "Error"}: ${data.error}\n`)
        if (response.status === 402) {
          alert(this.creditsExhaustedValue || "AI Credits exhausted! Please top up your wallet.")
        }
      }
    } catch (error) {
      this.insertIntoEditor(`\n${this.errorPrefixValue || "Error"}: ${error.message}\n`)
    } finally {
      this.enableButton(btn)
    }
  }

  async rewriteTone(e) {
    e.preventDefault()
    const text = this.getCurrentText()
    if (!text) return

    const btn = e.currentTarget
    this.disableButton(btn)

    this.insertIntoEditor(`\n🤖 Rewriting tone to ${btn.dataset.aiAssistToneParam}...\n`)

    try {
      const response = await this.postData(this.rewriteUrlValue, { text: text, tone: btn.dataset.aiAssistToneParam })
      await this.handleTransformResponse(response)
    } catch (error) {
      this.insertIntoEditor(`\n${this.errorPrefixValue || "Error"}: ${error.message}\n`)
    } finally {
      this.enableButton(btn)
    }
  }

  async fixGrammar(e) {
    e.preventDefault()
    const text = this.getCurrentText()
    if (!text) return

    const btn = e.currentTarget
    this.disableButton(btn)

    this.insertIntoEditor("\n🤖 Fixing grammar...\n")

    try {
      const response = await this.postData(this.grammarUrlValue, { text: text })
      await this.handleTransformResponse(response, "fixed")
    } catch (error) {
      this.insertIntoEditor(`\n${this.errorPrefixValue || "Error"}: ${error.message}\n`)
    } finally {
      this.enableButton(btn)
    }
  }

  async translate(e) {
    e.preventDefault()
    const text = this.getCurrentText()
    if (!text) return

    const btn = e.currentTarget
    this.disableButton(btn)
    
    this.insertIntoEditor(`\n🤖 Translating to customer's language...\n`)

    try {
      const response = await this.postData(this.translateUrlValue, { text: text })
      await this.handleTransformResponse(response, "translated")
    } catch (error) {
      this.insertIntoEditor(`\n${this.errorPrefixValue || "Error"}: ${error.message}\n`)
    } finally {
      this.enableButton(btn)
    }
  }

  disableButton(btn) {
    if (!btn) return
    btn.setAttribute("disabled", "disabled")
    btn.classList.add("opacity-50", "cursor-not-allowed")
  }

  enableButton(btn) {
    if (!btn) return
    btn.removeAttribute("disabled")
    btn.classList.remove("opacity-50", "cursor-not-allowed")
  }

  getCurrentText() {
    if (this.hasLexicalOutlet) {
      return this.lexicalOutlet.getText()
    }
    return ""
  }

  async handleTransformResponse(response, key = "rewritten") {
    const data = await response.json()
    if (data.success) {
      // Replace entire editor contents with the transformed text
      if (this.hasLexicalOutlet) {
        this.lexicalOutlet.clear()
        this.lexicalOutlet.insertText(data[key])
      }
    } else {
      this.insertIntoEditor(`\n${this.errorPrefixValue || "Error"}: ${data.error}\n`)
      if (response.status === 402) {
        alert(this.creditsExhaustedValue || "AI Credits exhausted! Please top up your wallet.")
      }
    }
  }

  insertIntoEditor(text) {
    if (this.hasLexicalOutlet) {
      this.lexicalOutlet.insertText(text)
    } else {
      console.warn("Lexical outlet not found for AI Assist.")
    }
  }
}
