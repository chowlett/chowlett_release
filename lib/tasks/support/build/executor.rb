Require_relative '../app'

module Build
  class Executor
    attr_accessor :app_name

    def execute
      puts "Building #{app_name}"
    end

    def initialize
      self.app_name =App.app_name
    end
  end
end