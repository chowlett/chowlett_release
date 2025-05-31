require 'aws-sdk-ecs'

module Deploy
  # Update the ECS service for the given app and environment. Typically done after a new task definition has been
  # registered. Updating the service restarts it with the new task definition.
  class EcsServiceUpdater
    attr_accessor :app_name, :environment, :service_name, :ecs_client

    def update
      puts "Processing cluster #{cluster_name}"

      set_service

      puts "Processing service #{service_name}"

      service = get_service

      update_result = update_service(service)

      if update_result[:no_newer_revision]
        puts "Restarted #{update_result[:latest_task_definition_arn]}"
      else
        puts "Replaced #{update_result[:running_task_definition_arn]} with #{update_result[:latest_task_definition_arn]}"
      end
    end

    def initialize(app_name:, environment:)
      self.app_name = app_name
      self.environment = environment
      self.ecs_client = Aws::ECS::Client.new
    end

    private

    def cluster_name
      "#{app_name}-#{environment}"
    end

    def get_service
      begin
        params = {
          cluster: cluster_name,
          services: [service_name]
        }
        resp = ecs_client.describe_services(params)
      rescue StandardError => e
        puts "Fatal error in describe_services: #{e}"
        puts "Parameters: #{JSON.pretty_generate(params)}"
        raise 'Error in describe_services'
      end

      services = resp[:services]
      raise 'No services found.' if services.nil? || services.empty?
      raise 'More than one service found.' if services.length > 1

      services.first
    end

    def get_latest_task_definition_arn(running_task_definition_arn)
      task_family = family_from_task_definition(running_task_definition_arn)

      begin
        params = {
          task_definition: task_family,
        }
        resp = ecs_client.describe_task_definition(params)
      rescue StandardError => e
        puts "Fatal error in describe_task_definition: #{e}"
        puts "Parameters: #{JSON.pretty_generate(params)}"
        raise 'Error in describe_task_definition'
      end

      resp.task_definition[:task_definition_arn]
    end

    def family_from_task_definition(task_definition)
      m = task_definition.match(/([^\/]+)(?:\:\d+)$/)

      m[1]
    end

    def set_service
      begin
        params = {
          cluster: cluster_name

        }
        resp = ecs_client.list_services(params)
      rescue StandardError => e
        puts "Fatal error in list_services: #{e}"
        puts "Parameters: #{JSON.pretty_generate(params)}"
        raise 'Error in list_services'
      end

      service_arns = resp[:service_arns]

      raise "Cluster '#{cluster_name}' contains no services." if service_arns.empty?
      raise "Cluster '#{cluster_name}' contains more than one service. Specify the service on the command line." \
        if service_arns.length > 1

      service_arn = service_arns.first
      m = /([^\/]+)$/.match(service_arn)

      raise "Unable to parse service arn: #{service_arn}" if m.nil?

      self.service_name = m[1]
    end

    def update_service(service)
      running_task_definition_arn = service[:task_definition]
      latest_task_definition_arn = get_latest_task_definition_arn(running_task_definition_arn)
      no_newer_revision = running_task_definition_arn == latest_task_definition_arn

      params = {
        cluster: cluster_name,
        service: service_name,
        task_definition: latest_task_definition_arn
      }

      params[:force_new_deployment] = true if no_newer_revision

      begin
        ecs_client.update_service(params)
      rescue StandardError => e
        puts "Fatal error in update_service: #{e}"
        puts "Parameters: #{JSON.pretty_generate(params)}"
        raise 'Error in update_service'
      end

      {
        running_task_definition_arn: running_task_definition_arn,
        latest_task_definition_arn: latest_task_definition_arn,
        no_newer_revision: no_newer_revision
      }
    end
  end
end
