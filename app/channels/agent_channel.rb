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

    # Create an Assistant with properly configured LLM
    assistant = Langchain::Assistant.new(
      llm: Langchain::LLM::Anthropic.new(
        api_key: api_key,
        default_options: {
          temperature: 0.7,
          max_tokens: 4096,
          model: "claude-3-sonnet-20240229"  # Explicitly specify the model
        }
      ),
      instructions: "You are a helpful AI assistant. Respond concisely and accurately to user queries."
    ) do |response_chunk|
      Rails.logger.debug "Response chunk in initialization block: #{response_chunk.inspect}"
    end

    handle_streaming_response(assistant, data)
  end

  def handle_streaming_response(assistant, data)
    transmit_start_message
    buffer = stream_response(assistant, data)
    transmit_final_message(buffer)
  end

  def transmit_start_message
    transmit({
      response: {},
      message_type: "assistant-start",
      timestamp: Time.current
    })
  end

  # Example chunks from Anthropic API:
  #
  # Initial message start:
  # {"type"=>"message_start",
  #  "message"=>
  #   {"id"=>"msg_01Le2vtbcmyqjGWuw7ghR4J7",
  #    "type"=>"message",
  #    "role"=>"assistant", 
  #    "model"=>"claude-3-5-sonnet-20240620",
  #    "content"=>[],
  #    "stop_reason"=>nil,
  #    "stop_sequence"=>nil,
  #    "usage"=>{"input_tokens"=>9, "cache_creation_input_tokens"=>0, "cache_read_input_tokens"=>0, "output_tokens"=>1}}}
  #
  # Content block start:
  # {"type"=>"content_block_start", "index"=>0, "content_block"=>{"type"=>"text", "text"=>""}}
  #
  # Ping:
  # {"type"=>"ping"}
  #
  # Content block delta with text:
  # {"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>"Hi"}}
  def stream_response(assistant, data)
    buffer = ""
    hit_token_limit = false
    Rails.logger.info "Starting stream_response..."
    
    begin
      # Add debug logging for the message being sent
      Rails.logger.debug "Sending message to assistant: #{data["message"]}"
      
      response = assistant.add_message_and_run!(content: data["message"]) do |chunk|
        Rails.logger.debug "Raw chunk received: #{chunk.inspect}"
        
        if chunk.is_a?(Hash)
          case chunk["type"]
          when "message_start"
            Rails.logger.info "Stream started with message ID: #{chunk["message"]["id"]}"
          when "content_block_delta"
            chunk_text = chunk.dig("delta", "text").to_s
            unless chunk_text.empty?
              Rails.logger.debug "Adding chunk text: #{chunk_text}"
              buffer += chunk_text
              transmit_chunk(chunk_text)
            end
          when "message_delta"
            if chunk["delta"]["stop_reason"] == "max_tokens"
              hit_token_limit = true
              Rails.logger.warn "Response hit max_tokens limit! Buffer length: #{buffer.length}"
              truncation_note = "\n\n[Note: Response was truncated due to length limits]"
              buffer += truncation_note
              transmit_chunk(truncation_note)
            end
          when "message_stop"
            Rails.logger.info "Stream completed. Final buffer length: #{buffer.length}"
          end
        else
          Rails.logger.warn "Received non-Hash chunk: #{chunk.inspect}"
        end
      end
      
      # Add debug logging for the response
      Rails.logger.debug "Assistant response: #{response.inspect}"
      
      Rails.logger.info "Stream processing completed"
      if hit_token_limit
        Rails.logger.warn "Response was truncated due to token limit"
      end
      
      if buffer.empty?
        Rails.logger.warn "No content received in buffer"
        buffer = "I apologize, but I wasn't able to generate a response. Please try again."
        transmit_chunk(buffer)
      end
      
      buffer
    rescue Faraday::Error => e
      begin
        error_response = e.response[:body]  # Already a Hash
        error_message = error_response.dig("error", "message")
        error_type = error_response.dig("error", "type")
        
        Rails.logger.error "API Error: #{error_type} - #{error_message}"
        Rails.logger.error "Full response body: #{error_response}"
        
        # Transmit a user-friendly error message
        transmit({
          response: "Sorry, there was an API error: #{error_message}",
          message_type: "error",
          timestamp: Time.current
        })
      rescue => parse_error
        Rails.logger.error "Failed to process error response: #{parse_error.message}"
        Rails.logger.error "Original error body: #{e.response[:body]}"
        raise e
      end
    rescue => e
      Rails.logger.error "Error in stream_response: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end
  end

  def transmit_chunk(chunk)
    transmit({
      response: chunk,
      message_type: "assistant-chunk",
      timestamp: Time.current
    })
  end

  def transmit_final_message(buffer)
    Rails.logger.info "Transmitting final message with buffer length: #{buffer.length}"
    
    response_data = {
      response: buffer,
      message_type: "assistant-complete",
      timestamp: Time.current
    }
    
    # Log the first and last part of the buffer instead of the whole thing
    preview_length = 100
    Rails.logger.debug "Final message preview: #{buffer[0..preview_length]}... (#{buffer.length} chars total)"
    transmit(response_data)
  end
end
