self.addEventListener("push", function(event) {
  if (event.data) {
    const data = event.data.json()
    const options = {
      body: data.body,
      icon: data.icon || (self.location.origin + "/icon.png"), // Use absolute URL for desktop push support
      badge: data.badge || (self.location.origin + "/icon.png"),
      data: data.data
    }
    
    event.waitUntil(
      self.registration.showNotification(data.title, options)
    )
  }
})

self.addEventListener("notificationclick", function(event) {
  event.notification.close()
  
  // Decide where to navigate based on notification data
  const data = event.notification.data
  let url = "/"
  
  if (data && data.resource_type === "Conversation") {
    url = `/conversations/${data.resource_id}`
  } else if (data && data.resource_type === "Message" && data.conversation_id) {
    url = `/conversations/${data.conversation_id}`
  }
  
  event.waitUntil(
    clients.matchAll({ type: "window" }).then(function(clientList) {
      for (let i = 0; i < clientList.length; i++) {
        let client = clientList[i]
        if (client.url === "/" && "focus" in client) {
          return client.focus()
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(url)
      }
    })
  )
})
