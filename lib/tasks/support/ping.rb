require_relative "./app"

module Ping
  include App
  def self.ping
    puts "Hello from strongstart_release for #{self.class.app_name}!"
  end
end
