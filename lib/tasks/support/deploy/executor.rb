require_relative '../app'

module Deploy
  class Executor
    attr_accessor :app_name, :environment, :version_tag

    def execute
      announce_start
    end

    def initialize( environment:, version_tag: nil )
      raise ArgumentError, "environment must be provided" if environment.nil? || environment.empty?
      raise ArgumentError, "environment must be one of :staging or :production" unless %i[staging production].include?(environment.downcase)

      self.app_name = App.app_name
      self.environment = environment
      self.version_tag = version_tag
    end

    private

    def announce_start
      if version_tag
        puts "Deploying #{app_name} build #{version_tag} to #{environment}"
      else
        puts "Deploying most recent build of #{app_name} to #{environment}"
      end
    end
  end
end
