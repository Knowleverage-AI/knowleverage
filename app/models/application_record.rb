# frozen_string_literal: true

# The base class for all ActiveRecord models in the application.
# Provides common model functionality and configuration.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
