import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["messages", "conveersations"]

  connect() {
    this.userId = this.data.get("user")
    this.token = this.data.get("token")
    this.consumer = createConsumer()
    
    this.subscription = this.consumer.subscriptions.create({
      channel: "SubscriptionChannel",
      connection_token: this.token,
      user_id: this.userId
    }, {
      received: (data) => {
        const url = this.configureUrl(data["event"]);
        const resourceId = JSON.parse(data["object"])["id"];
        
        this.appendData(url, resourceId);
      }
    })
  }
  
  configureUrl(broadcast_event) {
    if (broadcast_event == "message.created") {
      return "/messages/append_message"
    } else if (broadcast_event == "conversation.created") {
      return "/conversations/append_conversation"
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