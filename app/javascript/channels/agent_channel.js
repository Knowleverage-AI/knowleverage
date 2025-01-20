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
        // Remove any existing streaming container
        const streamingContainer = messageLog.querySelector('[data-stream-container="true"]')
        if (streamingContainer) {
          streamingContainer.removeAttribute('data-stream-container')
        }
        
        // Check if response includes truncation notice
        if (data.response.includes("[Note: Response was truncated")) {
          const truncationDiv = document.createElement('div')
          truncationDiv.classList.add('message', 'system', 'truncation-notice')
          truncationDiv.textContent = "Note: The response was truncated due to length limits"
          messageLog.appendChild(truncationDiv)
        }
        
        messageLog.scrollTop = messageLog.scrollHeight
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
