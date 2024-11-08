import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["messages", "conveersations"]

  connect() {
    this.url = this.data.get("url")
    this.userId = this.data.get("user")
    this.token = this.data.get("token")
    console.log("ON BODY")
    this.consumer = createConsumer(`${this.url}`)
    
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






// console.log(this.consumer)
// console.log(this.subscription)



// import { Controller } from "@hotwired/stimulus"
// import { createConsumer } from "@rails/actioncable"

// // Connects to data-controller="consumer"
// export default class extends Controller {
  
//   connect() {
    // const url = this.data.get("url")
    // const user = this.data.get("user")
    // const token = this.data.get("token")
    
//     const consumer = createConsumer(url)
//   }

// setTimeout(() => {
//   if (this.subscription) {
//     this.subscription.activity();
//     console.log("Called activity() on subscription after timeout");
//   } else {
//     console.error("Subscription is not initialized");
//   }
// }, 3000);
// }

// consumer.subscriptions.create({ channel: "SubscriptionChannel", connection_token: token, user: user })

  // setTimeout(() => {
    //   this.subscription.activity();
    // }, 123456);
    
    
    // fetch(`${url}/messages/append_message?id=${messageId}`, {