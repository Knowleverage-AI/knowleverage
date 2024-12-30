# frozen_string_literal: true

# The base controller for all controllers in the application.
# Provides common functionality and configuration for controllers.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
