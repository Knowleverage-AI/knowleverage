import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["messageLog", "input", "sendButton", "status"]
  
  connect() {
    this.setupChannel()
    this.messageHistory = []
    this.isProcessing = false
  }

  setupChannel() {
    this.channel = consumer.subscriptions.create("AgentChannel", {
      connected: () => this.handleConnectionChange("Connected"),
      disconnected: () => this.handleConnectionChange("Disconnected"),
      received: (data) => this.handleMessage(data)
    })
  }

  handleConnectionChange(status) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = status
    }
  }

  handleMessage(data) {
    console.log("Received message data:", data)
    switch(data.message_type) {
      case "system":
        this.addSystemMessage(data.response)
        break
      case "assistant-start":
        // Create a new message div for streaming
        this.currentStreamDiv = document.createElement("div")
        this.currentStreamDiv.classList.add("message", "assistant", "streaming")
        this.messageLogTarget.appendChild(this.currentStreamDiv)
        break
      case "assistant-chunk":
        // Append the chunk to the current message
        if (this.currentStreamDiv) {
          console.log("Received chunk:", data.response)
          this.currentStreamDiv.textContent += data.response
          this.scrollToBottom()
        }
        break
      case "assistant-complete":
        // Remove streaming class when complete
        if (this.currentStreamDiv) {
          this.currentStreamDiv.classList.remove("streaming")
        }
        this.currentStreamDiv = null
        this.setProcessing(false)
        break
      case "error":
        this.addErrorMessage(data.response)
        this.setProcessing(false)
        break
      case "status":
        if (data.status === "processing") {
          this.setProcessing(true)
        }
        break
      default:
        console.warn("Unknown message type:", data.message_type)
    }
    
    this.messageHistory.push(data)
    this.scrollToBottom()
  }

  send(event) {
    event.preventDefault()
    
    if (this.isProcessing || !this.inputTarget.value.trim()) {
      return
    }

    const message = this.inputTarget.value
    console.log("Sending message:", message)
    
    // Add user message to chat
    this.addUserMessage(message)
    
    // Send to server - using perform instead of sendMessage
    this.channel.perform("receive", { message: message })
    
    // Clear input
    this.inputTarget.value = ""
    
    this.scrollToBottom()
  }

  addUserMessage(text) {
    this.addMessageToLog('user', text)
  }

  addAssistantMessage(text) {
    this.addMessageToLog('assistant', text)
  }

  addSystemMessage(text) {
    this.addMessageToLog('system', text)
  }

  addErrorMessage(text) {
    this.addMessageToLog('error', text)
  }

  addMessageToLog(type, text) {
    const messageDiv = document.createElement("div")
    messageDiv.classList.add("message", type)
    messageDiv.textContent = text
    this.messageLogTarget.appendChild(messageDiv)
  }

  scrollToBottom() {
    this.messageLogTarget.scrollTop = this.messageLogTarget.scrollHeight
  }

  setProcessing(isProcessing) {
    this.isProcessing = isProcessing
    if (this.hasSendButtonTarget) {
      this.sendButtonTarget.disabled = isProcessing
      this.sendButtonTarget.textContent = isProcessing ? "Sending..." : "Send"
    }
  }

  // Handle Enter key to send message (Shift+Enter for new line)
  keyPress(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.send(event)
    }
  }

  disconnect() {
    if (this.channel) {
      this.channel.unsubscribe()
    }
  }
}
