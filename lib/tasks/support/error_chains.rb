# frozen_string_literal: true

# Methods for displaying the "cause" chain of an error.
# Usage:
#   ErrorChains.puts_error_chain(e) or ErrorChains.log_error_chain(e)

require 'rails'
module ErrorChains
  def self.puts_error_chain(e)
    while e
      puts e.inspect
      e = e.cause
      puts "Caused by:" if e
    end
  end

  def self.log_error_chain(e)
    while e
      Rails.logger.error e.inspect
      e = e.cause
      Rails.logger.error "Caused by:" if e
    end
  end
end
