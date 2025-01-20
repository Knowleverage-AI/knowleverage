# frozen_string_literal: true

# AgentChannel handles real-time communication for AI agent interactions
# through ActionCable WebSockets. It manages message processing and
# connection-specific communication channels.
class AgentChannel < ApplicationCable::Channel
  delegate :connection_identifier, to: :connection

  def subscribed
    stream_from "agent_channel_#{connection_identifier}"
    send_welcome_message
  end

  def receive(data)
    Rails.logger.info "AgentChannel received message: #{data.inspect}"
    return if data["message"].blank?

    send_processing_status
    process_and_transmit_response(data)
  rescue StandardError => e
    handle_error(e)
  end

  private

  def send_welcome_message
    transmit({
      response: "Hello! I'm your AI assistant. How can I help you today?",
      message_type: "system",
      timestamp: Time.current
    })
  end

  def send_processing_status
    transmit({
      message_type: "status",
      status: "processing",
      timestamp: Time.current
    })
  end

  def process_and_transmit_response(data)
    Rails.logger.info "Processing message..."
    processed = process_message(data)
    
    # Don't return the processed boolean
    Rails.logger.info "Message processing completed"
  end

  def handle_error(error)
    Rails.logger.error("Error processing message: #{error.message}")
    Rails.logger.error("Error class: #{error.class}")
    Rails.logger.error("Full error details:")
    Rails.logger.error(error.full_message)

    transmit({
      response: "I apologize, but I encountered an error processing your request. Error: #{error.message}",
      message_type: "error",
      timestamp: Time.current
    })
  end

  def process_message(data)
    require "langchain"

    api_key = ENV.fetch("ANTHROPIC_API_KEY")
    Rails.logger.info "Using API key: #{api_key[0..3]}..."

    llm = Langchain::LLM::Anthropic.new(
      api_key: api_key,
      llm_options: {
        stream: true
      },
      default_options: {
        temperature: 0.7,
        max_tokens: 4096,
        model: "claude-3-sonnet-20240229",
        stream: true
      }
    )

    assistant = Langchain::Assistant.new(
      llm: llm,
      instructions: "You are a helpful AI assistant. Respond concisely and accurately to user queries."
    ) do |response_chunk|
      if response_chunk["type"] == "content_block_delta" && 
         response_chunk.dig("delta", "type") == "text_delta"
        chunk_text = response_chunk.dig("delta", "text").to_s
        unless chunk_text.empty?
          transmit({
            response: chunk_text,
            message_type: "assistant-chunk",
            timestamp: Time.current
          })
        end
      end
    end

    # Send start message
    transmit({
      response: {},
      message_type: "assistant-start", 
      timestamp: Time.current
    })

    # Run the assistant with the message
    assistant.add_message_and_run!(content: data["message"])

    # Send completion message
    transmit({
      message_type: "assistant-complete",
      timestamp: Time.current
    })
  end

end
