require_relative '../app'

module Deploy
  class Executor
    attr_accessor :app_name, :environment

    def execute
      puts "Deploying #{app_name} to #{environment}"
    end

    def initialize( environment:)
      raise ArgumentError, "environment must be provided" if environment.nil? || environment.empty?
      raise ArgumentError, "environment must be one of :staging or :production" unless %i[staging production].include?(environment.downcase)

      self.app_name = App.app_name
      self.environment = environment
    end
  end
end
