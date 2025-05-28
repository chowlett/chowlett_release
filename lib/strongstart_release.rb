require "rails"
require_relative "strongstart_release/railtie" if defined?(Rails)

require_relative "strongstart_release/version"

module StrongstartRelease
  class Error < StandardError; end
  # Your code goes here...
end

