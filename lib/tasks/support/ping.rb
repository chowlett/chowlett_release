require_relative "./app"

module Ping
  def self.ping
    puts "Hello from strongstart_release for #{App.app_name}!"
  end
end
