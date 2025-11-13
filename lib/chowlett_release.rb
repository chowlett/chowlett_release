require 'rails'
require_relative 'chowlett_release/railtie' if defined?(Rails)

require_relative 'chowlett_release/version'

module ChowlettRelease
  class Error < StandardError; end
  # Your code goes here...
end
