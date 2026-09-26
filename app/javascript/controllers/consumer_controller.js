import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["messages", "conveersations"]

  connect() {
    this.userId = this.element.dataset.consumerUser
    this.token = this.element.dataset.consumerToken
    
    if (!this.token) {
      console.warn("[Deskbolic] No connection token — ActionCable will NOT connect")
      return
    }

    const metaUrl = document.querySelector("meta[name='action-cable-url']")?.content
    const cableUrl = metaUrl 
      ? `${metaUrl}?user_token=${this.token}`
      : `/cable?user_token=${this.token}`

    this.consumer = createConsumer(cableUrl)
    
    this._lastMessageSoundTime = 0
    this._lastConversationSoundTime = 0
    this._isMuted = false

    this._soundToggleHandler = (e) => {
      if (typeof e.detail?.muted === "boolean") {
        this._isMuted = e.detail.muted
      } else {
        this._isMuted = !this._isMuted
      }
    }
    window.addEventListener("deskbolic:sound:toggle", this._soundToggleHandler)

    this._sentSoundHandler = () => this.playSentMessageSound()
    window.addEventListener("deskbolic:sound:sent", this._sentSoundHandler)

    // Unlock AudioContext on first user interaction for incoming message alerts
    this._audioUnlockHandler = () => {
      if (!this.audioCtx) {
        const AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (AudioCtx) this.audioCtx = new AudioCtx();
      }
      if (this.audioCtx && this.audioCtx.state === "suspended") {
        this.audioCtx.resume();
      }
    };
    document.addEventListener("click", this._audioUnlockHandler, { once: true, passive: true });

    this.subscription = this.consumer.subscriptions.create({
      channel: "SubscriptionChannel",
      connection_token: this.token,
      user_id: this.userId
    }, {
      connected: () => {
        // Ping every 15 seconds to keep the Redis ActivityHelpers alive
        this.pingInterval = setInterval(() => {
          this.subscription.perform("ping")
        }, 15000);
      },
      disconnected: () => {
        if (this.pingInterval) clearInterval(this.pingInterval);
      },
      received: (data) => {
        if (data.event === "unread_counts.updated") {
          window.dispatchEvent(new CustomEvent("deskbolic:unread-counts-updated", { detail: JSON.parse(data.object) }));
          return;
        }

        const eventType = data["event"];
        let objectData = {};
        if (data["object"]) {
          try {
            objectData = typeof data["object"] === "string" ? JSON.parse(data["object"]) : data["object"];
          } catch (e) {
            console.error("Failed to parse objectData", e);
          }
        }
        const resourceId = objectData["id"];

        if (eventType === "message.created") {
          // Play smart incoming message notification sound for dashboard agents
          this.handleIncomingMessageAlert(objectData);

          if (document.getElementById(`message_${resourceId}`)) return;

          const activeConversationId = document.querySelector(".conversation#oppp")?.dataset.conversationId;
          const url = this.configureUrl(eventType);
          let fetchUrl = `${url}?id=${resourceId}`;
          if (activeConversationId) {
            fetchUrl += `&active_conversation_id=${activeConversationId}`;
          }
          
          fetch(fetchUrl, {
            method: 'GET',
            headers: { Accept: 'text/vnd.turbo-stream.html' },
          }).then((response) => response.text()).then((html) => {
            Turbo.renderStreamMessage(html);
          });

          // Reorder the conversation to the top of the sidebar
          const conversationId = objectData.conversation?.id;
          if (conversationId) {
            this.reorderConversation(conversationId);
          }
        } else if (eventType === "conversation.created") {
          // Play distinct 3-note ascending chord for new incoming conversations
          this.handleNewConversationAlert(objectData);

          const url = this.configureUrl(eventType);
          if (url) {
            const activeConversationId = document.querySelector(".conversation#oppp")?.dataset.conversationId;
            this.appendData(url, resourceId, activeConversationId);
          }
        } else if (eventType === "activity.created") {
          if (document.getElementById(`activity_${resourceId}`)) return;
          const activeConversationId = document.querySelector(".conversation#oppp")?.dataset.conversationId;
          const url = this.configureUrl(eventType);
          if (url && activeConversationId && objectData.trackable_id === activeConversationId) {
            fetch(`${url}?id=${resourceId}`, {
              method: 'GET',
              headers: { Accept: 'text/vnd.turbo-stream.html' },
            }).then(r => r.text()).then(html => Turbo.renderStreamMessage(html));
          }
        } else {
          const url = this.configureUrl(eventType);
          if (url) {
            const activeConversationId = document.querySelector(".conversation#oppp")?.dataset.conversationId;
            this.appendData(url, resourceId, activeConversationId);
          } else {
            console.warn(`[Deskbolic] Unhandled broadcast event: ${eventType}`);
          }
        }
      }
    })
  }

  disconnect() {
    if (this._soundToggleHandler) {
      window.removeEventListener("deskbolic:sound:toggle", this._soundToggleHandler);
      this._soundToggleHandler = null;
    }
    if (this._sentSoundHandler) {
      window.removeEventListener("deskbolic:sound:sent", this._sentSoundHandler);
      this._sentSoundHandler = null;
    }
    if (this._audioUnlockHandler) {
      document.removeEventListener("click", this._audioUnlockHandler);
      this._audioUnlockHandler = null;
    }
    if (this.audioCtx) {
      try { this.audioCtx.close(); } catch(e) {}
      this.audioCtx = null;
    }
    if (this.subscription) {
      this.consumer.subscriptions.remove(this.subscription)
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }
  
  configureUrl(broadcast_event) {
    if (broadcast_event == "message.created") {
      return this.localizedPath("/messages/append_message")
    } else if (broadcast_event == "conversation.created") {
      return this.localizedPath("/conversations/append_conversation")
    } else if (broadcast_event == "conversation.updated") {
      return this.localizedPath("/conversations/reorder_conversation")
    } else if (broadcast_event == "message.updated") {
      return this.localizedPath("/messages/update_message")
    } else if (broadcast_event == "activity.created") {
      return this.localizedPath("/activities/append_activity")
    } else if (broadcast_event == "notification.created") {
      return this.localizedPath("/notifications/update_badge")
    }
  }

  localizedPath(path) {
    const locale = document.documentElement.lang
    return locale && locale !== "en" ? `/${locale}${path}` : path
  }
  
  appendData(url, resourceId, activeConversationId) {
    let fetchUrl = `${url}?id=${resourceId}`;
    if (activeConversationId) {
      fetchUrl += `&active_conversation_id=${activeConversationId}`;
    }
    fetch(fetchUrl, {
      method: 'GET',
      headers: {
        Accept: 'text/vnd.turbo-stream.html'
      },
    }).then((response) => response.text()).
    then((html) => {
      Turbo.renderStreamMessage(html);
    })
  }

  reorderConversation(conversationId) {
    const activeConversationId = document.querySelector(".conversation#oppp")?.dataset.conversationId;
    let fetchUrl = `${this.localizedPath("/conversations/reorder_conversation")}?id=${conversationId}`;
    if (activeConversationId) {
      fetchUrl += `&active_conversation_id=${activeConversationId}`;
    }
    fetch(fetchUrl, {
      method: 'GET',
      headers: { Accept: 'text/vnd.turbo-stream.html' },
    }).then((response) => response.text()).then((html) => {
      Turbo.renderStreamMessage(html);
    })
  }

  handleIncomingMessageAlert(objectData) {
    if (this._isMuted) return;

    // Only alert on incoming customer messages
    const isIncoming = objectData.incoming === true || objectData.incoming === "true";
    if (!isIncoming) return;

    // 1. Agent Assignment Filter:
    // If the conversation is assigned to another agent, do not play notification sound.
    // If unassigned (inbox triage) or assigned to me, alert the agent.
    const assigneeId = objectData.conversation?.assignee_id ?? objectData.assignee_id;
    if (assigneeId && this.userId && String(assigneeId) !== String(this.userId)) {
      return;
    }

    // 2. Active Conversation & Tab Focus Suppression:
    // If the agent is actively looking at this conversation right now in a focused tab,
    // suppress the chime to avoid distracting them while they read.
    const activeConversationId = document.querySelector(".conversation#oppp")?.dataset.conversationId;
    const messageConversationId = objectData.conversation?.id ?? objectData.conversation_id;
    const isViewingThisConversation = activeConversationId && messageConversationId && String(activeConversationId) === String(messageConversationId);
    const isTabFocused = !document.hidden && (typeof document.hasFocus === "function" ? document.hasFocus() : true);

    if (isViewingThisConversation && isTabFocused) {
      return;
    }

    // 3. Debounce / Anti-Machine-Gun Cooldown (2.5 seconds):
    const now = Date.now();
    if (now - this._lastMessageSoundTime < 2500) {
      return;
    }
    this._lastMessageSoundTime = now;

    this.playNotificationSound();
  }

  handleNewConversationAlert(objectData) {
    if (this._isMuted) return;

    // 1. Assignment Filter:
    // If assigned to another agent, don't alert.
    const assigneeId = objectData.assignee_id;
    if (assigneeId && this.userId && String(assigneeId) !== String(this.userId)) {
      return;
    }

    // 2. Anti-flood Cooldown (3 seconds):
    const now = Date.now();
    if (now - this._lastConversationSoundTime < 3000) {
      return;
    }
    this._lastConversationSoundTime = now;

    this.playNewConversationSound();
  }

  toggleMute(explicitState) {
    if (typeof explicitState === "boolean") {
      this._isMuted = explicitState;
    } else {
      this._isMuted = !this._isMuted;
    }
    return this._isMuted;
  }

  _getAudioContext() {
    if (!this.audioCtx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) this.audioCtx = new AudioCtx();
    }
    if (this.audioCtx && this.audioCtx.state === "suspended") {
      this.audioCtx.resume();
    }
    return this.audioCtx;
  }

  // 2-tone pleasant chime (C5 -> E5) for incoming replies on an existing conversation
  playNotificationSound() {
    if (this._isMuted) return;
    try {
      const ctx = this._getAudioContext();
      if (!ctx) return;

      const now = ctx.currentTime;

      // Tone 1: C5 (523.25 Hz)
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = "sine";
      osc1.frequency.setValueAtTime(523.25, now);
      gain1.gain.setValueAtTime(0.12, now);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.18);

      // Tone 2: E5 (659.25 Hz) with gentle delay
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = "sine";
      osc2.frequency.setValueAtTime(659.25, now + 0.1);
      gain2.gain.setValueAtTime(0.15, now + 0.1);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.32);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.1);
      osc2.stop(now + 0.32);
    } catch (e) {
      console.debug("[Deskbolic] Audio notification error:", e);
    }
  }

  // Bright 3-note ascending chord (C5 -> E5 -> G5) to alert agent of a brand-new conversation
  playNewConversationSound() {
    if (this._isMuted) return;
    try {
      const ctx = this._getAudioContext();
      if (!ctx) return;

      const now = ctx.currentTime;

      // Note 1: C5 (523.25 Hz)
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = "sine";
      osc1.frequency.setValueAtTime(523.25, now);
      gain1.gain.setValueAtTime(0.12, now);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.15);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.15);

      // Note 2: E5 (659.25 Hz)
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = "sine";
      osc2.frequency.setValueAtTime(659.25, now + 0.09);
      gain2.gain.setValueAtTime(0.14, now + 0.09);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.24);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.09);
      osc2.stop(now + 0.24);

      // Note 3: G5 (783.99 Hz)
      const osc3 = ctx.createOscillator();
      const gain3 = ctx.createGain();
      osc3.type = "sine";
      osc3.frequency.setValueAtTime(783.99, now + 0.18);
      gain3.gain.setValueAtTime(0.16, now + 0.18);
      gain3.gain.exponentialRampToValueAtTime(0.001, now + 0.38);
      osc3.connect(gain3);
      gain3.connect(ctx.destination);
      osc3.start(now + 0.18);
      osc3.stop(now + 0.38);
    } catch (e) {
      console.debug("[Deskbolic] Audio notification error:", e);
    }
  }

  // Soft tactile pop/click (40ms) when agent sends a message or status update
  playSentMessageSound() {
    if (this._isMuted) return;
    try {
      const ctx = this._getAudioContext();
      if (!ctx) return;

      const now = ctx.currentTime;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = "sine";
      osc.frequency.setValueAtTime(440, now);
      osc.frequency.exponentialRampToValueAtTime(220, now + 0.04);

      gain.gain.setValueAtTime(0.08, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.04);
    } catch (e) {}
  }
}