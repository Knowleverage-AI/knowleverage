import consumer from "channels/consumer"

const updateConnectionStatus = (status) => {
  const statusElement = document.getElementById('connection-status')
  if (statusElement) {
    statusElement.textContent = status
  }
}

consumer.subscriptions.create("AgentChannel", {
  connected() {
    console.log("AgentChannel connected")
    updateConnectionStatus("Connected")
  },

  disconnected() {
    console.warn("AgentChannel disconnected")
    updateConnectionStatus("Disconnected")
  },

  received(data) {
    console.log("Received message:", data)
    this.handleMessage(data)
  },

  handleMessage(data) {
    console.log("Received message:", data)
    const messageLog = document.querySelector('[data-chat-target="messageLog"]')
    if (!messageLog) return

    switch(data.message_type) {
      case 'assistant-start':
        // Create a new message container for the streaming response
        const streamContainer = document.createElement('div')
        streamContainer.classList.add('message', 'assistant')
        streamContainer.dataset.streamContainer = 'true'
        messageLog.appendChild(streamContainer)
        break
        
      case 'assistant-chunk':
        // Append chunk to the current stream container
        const currentContainer = messageLog.querySelector('[data-stream-container="true"]')
        if (currentContainer) {
          currentContainer.textContent += data.response
        }
        break
        
      case 'assistant-complete':
        // Finalize the streaming container and remove the streaming flag
        const streamingContainer = messageLog.querySelector('[data-stream-container="true"]')
        if (streamingContainer) {
          streamingContainer.textContent = data.response // Set complete response
          streamingContainer.removeAttribute('data-stream-container')
        }
        messageLog.scrollTop = messageLog.scrollHeight // Scroll to bottom
        break

      case 'error':
        const errorDiv = document.createElement('div')
        errorDiv.classList.add('message', 'error')
        errorDiv.textContent = data.response
        messageLog.appendChild(errorDiv)
        messageLog.scrollTop = messageLog.scrollHeight
        break
    }
  }
})
