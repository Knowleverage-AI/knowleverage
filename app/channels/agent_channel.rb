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
    Rails.logger.info "Processed response: #{processed.inspect}"
    transmit(processed)
  end

  def handle_error(error)
    binding.pry
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
      api_key: api_key
    )

    handle_streaming_response(llm, data)
  end

  def handle_streaming_response(llm, data)
    transmit_start_message
    buffer = stream_response(llm, data)
    transmit_completion_message(buffer)
  end

  def transmit_start_message
    transmit({
      response: {},
      message_type: "assistant-start",
      timestamp: Time.current
    })
  end

  def stream_response(llm, data)
    buffer = ""
    llm.complete(
      prompt: data["message"],
      max_tokens: 1000,
      temperature: 0.7,
      stream: true
    ) do |chunk|
      buffer += chunk
      transmit_chunk(chunk)
    end
    buffer
  end

  def transmit_chunk(chunk)
    binding.pry
    transmit({
      response: chunk,
      message_type: "assistant-chunk",
      timestamp: Time.current
    })
  end

  def transmit_completion_message(buffer)
    binding.pry
    transmit({
      response: buffer,
      message_type: "assistant-complete",
      timestamp: Time.current
    })
  end
end
