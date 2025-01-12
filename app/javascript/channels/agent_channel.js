import consumer from "channels/consumer"

const updateConnectionStatus = (status) => {
   const statusElement = document.getElementById('connection-status')
   if (statusElement) {
     statusElement.textContent = status
   }
 }

consumer.subscriptions.create("AgentChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log("AgentChannel connected")
    updateConnectionStatus("Connected")
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.warn("AgentChannel disconnected")
    updateConnectionStatus("Disconnected")
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log("Received message:", data)
    this.handleMessage(data)
  },


  handleMessage(data) {
    // Process incoming messages
    if (data.response) {
      // Add your UI update logic here
      console.log("Agent response:", data.response)
    }
  }
})
