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
}