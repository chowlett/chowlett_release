# frozen_string_literal: true

require 'rails'

# Methods for displaying the "cause" chain of an error.
# Usage:
#   ErrorChains.puts_error_chain(error) or ErrorChains.log_error_chain(error)
module ErrorChains
  def self.puts_error_chain(error)
    while error
      puts error.inspect
      error = error.cause
      puts 'Caused by:' if error
    end
  end

  def self.log_error_chain(error)
    while error
      Rails.logger.error error.inspect
      error = error.cause
      Rails.logger.error 'Caused by:' if error
    end
  end
end
