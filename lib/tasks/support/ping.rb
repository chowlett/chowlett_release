require_relative "./app"

# Module to provide a simple gem ping functionality. A smoke test to ensure the gem is loaded and functional.
module Ping
  def self.ping
    puts "Hello from strongstart_release for #{App.app_name}!"
  end
end
