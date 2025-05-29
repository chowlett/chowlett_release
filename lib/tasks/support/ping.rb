require_relative "./app"

module Ping
  include App
  def self.ping
    puts "Hello from strongstart_release for #{app_name}!"
  end
end
