import consumer from "channels/consumer"

// Remove all message handling logic and just export the consumer
export default consumer.subscriptions.create("AgentChannel", {
  connected() {
    console.log("AgentChannel connected")
  },

  disconnected() {
    console.warn("AgentChannel disconnected")
  }
})
