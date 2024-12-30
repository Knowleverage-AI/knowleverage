# frozen_string_literal: true

# The base mailer for all mailers in the application.
# Provides common email functionality and configuration.
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
