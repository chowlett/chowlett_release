require_relative '../app'
require_relative './error'

module Deploy
  # Run the deployment
  class Executor
    attr_accessor :app_name, :environment, :version_tag, :dry_run

    def execute
      announce_start
      register_task_definition
      update_ecs_service
    rescue StandardError
      raise Deploy::Error, 'Error during deployment'
    end

    def initialize(environment:, version_tag: nil, dry_run: false)
      raise ArgumentError, 'environment must be provided' if environment.nil? || environment.empty?
      unless %i[staging production].include?(environment.downcase)
        raise ArgumentError, 'environment must be one of :staging or :production'
      end

      self.app_name = App.app_name
      self.environment = environment
      self.version_tag = version_tag
      self.dry_run = dry_run
    end

    private

    def announce_start
      dry_run_message = dry_run ? ' (dry run)' : ''
      if version_tag
        puts "Deploying #{app_name} build #{version_tag} to #{environment}#{dry_run_message}"
      else
        puts "Deploying most recent build of #{app_name} to #{environment}#{dry_run_message}"
      end
    end

    def register_task_definition
      registrar = Deploy::EcsTaskRegistrar.new(
        app_name: app_name, environment: environment, image_tag: version_tag, dry_run:
      )
      registrar.register
    end

    def update_ecs_service
      service_updater = Deploy::EcsServiceUpdater.new(app_name: app_name, environment: environment, dry_run:)
      service_updater.update
    end
  end
end
