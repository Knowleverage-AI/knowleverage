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
    @response = client.get(url)
    # binding.pry
  end
end
