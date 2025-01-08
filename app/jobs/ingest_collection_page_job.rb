# frozen_string_literal: true

# A *collection article* is a web page containing a list of URLs to *single
# articles*, usually with some short-descriptive context.
#
# This jobs extracts the single article URLs and their context descriptions,
# and delegates their ingestion to a dedicated job.
class IngestCollectionPageJob < ApplicationJob
  include HasClient

  queue_as :default

  def perform(url:)
    page_content = assistant.tools["HttpClient"].get(url: url)
    prompt = ARTICLE_EXTRACTION_PROMPT.format(html_content: page_content.to_html)
    response = assistant.chat(messages: [{ role: "user", content: prompt }])
    binding.pry

    # Step 3: Parse the response and enqueue jobs for individual articles
    articles = JSON.parse(response.chat_completion)
    binding.pry
    articles.each do |article|
      binding.pry
      # IngestSingleArticleJob.perform_later(url: article["url"], description: article["description"])
    end
  rescue => e
    Rails.logger.error "Error processing collection page: #{e.message}"
    raise e if Rails.env.development? # Re-raise in development for debugging
  end

  private

  def assistant
    @assistant ||= Langchain::Assistant.new(
      llm: llm,
      instructions: "You're a knowledge aggregator, extracting valuable information from sources.",
      tools: [http_client]
    )
  end

  def llm_adapter
    @llm_adapter ||= Langchain::Assistant::LLM::Adapter.build(llm)
  end

  def llm
    @llm ||= Langchain::LLM::Anthropic.new(
      api_key: ENV.fetch("ANTHROPIC_API_KEY")
    )
  end

  def http_client
    @http_client ||= Langchain::Tool::HttpClient.new
  end

   # Define the prompt template for article extraction
  ARTICLE_EXTRACTION_PROMPT = Langchain::Prompt::PromptTemplate.new(
    template: <<~PROMPT,
      Extract all article links and their descriptions from this HTML content.
      Return only a JSON array with objects containing 'url' and 'description' fields.

      HTML Content:
      {html_content}
    PROMPT
    input_variables: ["html_content"]
  )
end
