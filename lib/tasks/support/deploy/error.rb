# frozen_string_literal: true

module Deploy
  # Wrapper for errors that occur during the deploy process. Details are in the cause.
  class Error < StandardError
    def initialize(msg = 'An error occurred during the deploy process')
      super(msg)
    end
  end
end
