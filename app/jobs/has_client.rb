# frozen_string_literal: true

# Providing a client method and (overwritable) instanciation for HTTP requests.
module HasClient
  extend ActiveSupport::Concern

  included do
    def client
      @client ||= Faraday.new do |f|
        f.use Faraday::Response::Logger
        f.use Faraday::Response::RaiseError
        f.use Faraday::HttpCache, store: Rails.cache, serializer: Marshal, logger: Rails.logger
      end
    end
  end
end
