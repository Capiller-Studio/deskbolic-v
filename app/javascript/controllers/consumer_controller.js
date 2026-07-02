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
      received: (data) => {
        if (data.event === "unread_counts.updated") {
          window.dispatchEvent(new CustomEvent("deskbolic:unread-counts-updated", { detail: JSON.parse(data.object) }));
          return;
        }

        const eventType = data["event"];
        const objectData = JSON.parse(data["object"]);
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
            this.appendData(url, resourceId);
          } else {
            console.warn(`[Deskbolic] Unhandled broadcast event: ${eventType}`);
          }
        }
      }
    })
  }
  
  configureUrl(broadcast_event) {
    if (broadcast_event == "message.created") {
      return "/messages/append_message"
    } else if (broadcast_event == "conversation.created") {
      return "/conversations/append_conversation"
    } else if (broadcast_event == "message.updated") {
      return "/messages/update_message"
    } else if (broadcast_event == "activity.created") {
      return "/activities/append_activity"
    } else if (broadcast_event == "notification.created") {
      return "/notifications/update_badge"
    }
  }
  
  appendData(url, resourceId) {
    fetch(`${url}?id=${resourceId}`, {
      method: 'GET',
      headers: {
        Accept: 'text/vnd.turbo-stream.html'
      },
    }).then((response) => response.text()).
    then((html) => {
      Turbo.renderStreamMessage(html);
    })
  }
}