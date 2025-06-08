# frozen_string_literal: true

module Build
  # Wrapper for errors that occur during the build process. Details are in the cause.'
  class Error < StandardError
    def initialize(msg = 'An error occurred during the build process')
      super(msg)
    end
  end
end
