# frozen_string_literal: true

module Langchain
  module Tool
    # A Langchain tool for fetching HTML from an URL.
    class HttpClient
      extend Langchain::ToolDefinition
      include Langchain::DependencyHelper

      define_function :get, description: "Fetch a web page" do
        property :url, type: "string", description: "URL to fetch", required: true
      end

      def initialize
        depends_on "faraday"
        depends_on "nokogiri"
      end

      def get(url:)
        response = Faraday.get(url)
        raise "Failed to fetch page: #{response.status}" unless response.success?

        Nokogiri::HTML(response.body)
      end
    end
  end
end
