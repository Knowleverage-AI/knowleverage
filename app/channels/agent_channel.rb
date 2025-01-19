# frozen_string_literal: true

# AgentChannel handles real-time communication for AI agent interactions
# through ActionCable WebSockets. It manages message processing and
# connection-specific communication channels.
class AgentChannel < ApplicationCable::Channel
  delegate :connection_identifier, to: :connection

  def subscribed
    # Stream from a unique channel for this connection
    stream_from "agent_channel_#{connection_identifier}"

    # Send welcome message
    transmit({
      response: "Hello! I'm your AI assistant. How can I help you today?",
      message_type: "system",
      timestamp: Time.current
    })
  end

  def receive(data)
    Rails.logger.info "AgentChannel received message: #{data.inspect}"
    return if data["message"].blank?

    # Acknowledge receipt
    transmit({
      message_type: "status",
      status: "processing",
      timestamp: Time.current
    })

    # Process and respond only to this client
    begin
      Rails.logger.info "Processing message..."
      processed = process_message(data)
      Rails.logger.info "Processed response: #{processed.inspect}"
      transmit(processed)
    rescue StandardError => e
      Rails.logger.error("Error processing message: #{e.message}")
      Rails.logger.error("Error class: #{e.class}")
      Rails.logger.error("Full error details:")
      Rails.logger.error(e.full_message)
      transmit({
        response: "I apologize, but I encountered an error processing your request. Error: #{e.message}",
        message_type: "error",
        timestamp: Time.current
      })
    end
  end

  private

  def process_message(data)
    require "langchain"

    api_key = ENV.fetch("ANTHROPIC_API_KEY")
    Rails.logger.info "Using API key: #{api_key[0..3]}..."

    llm = Langchain::LLM::Anthropic.new(
      api_key: api_key
    )

    # Start a new message
    transmit({
      response: "",
      message_type: "assistant-start",
      timestamp: Time.current
    })

    buffer = ""

    llm.complete(
      prompt: data["message"],
      max_tokens: 1000,
      temperature: 0.7,
      stream: true # Enable streaming
    ) do |chunk|
      buffer += chunk
      # Send each chunk as it arrives
      transmit({
        response: chunk,
        message_type: "assistant-chunk",
        timestamp: Time.current
      })
    end

    # Send completion message
    transmit({
      response: buffer,
      message_type: "assistant-complete",
      timestamp: Time.current
    })
  end
end
