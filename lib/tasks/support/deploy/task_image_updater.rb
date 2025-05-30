require 'aws-sdk-ecs'
require 'aws-sdk-ecr'

module Deploy
  class TaskImageUpdater
    attr_accessor :app_name, :environment, :new_image_tag, :ecr_client, :ecs_client

    def update
      task_definition = get_task_definition

      if self.new_image_tag.nil?
        self.new_image_tag = find_most_recent_tag(task_definition)

        puts "Using most recent image tag: #{new_image_tag}"
      end

      puts "Current task revision: #{task_definition[:revision]}"

      new_task_arn = update_task_definition(task_definition)

      puts("Task #{new_task_arn} has been registered with image tag #{new_image_tag}")
    end

    def initialize(app_name:, environment:, image_tag: nil)
      self.app_name = app_name
      self.environment = environment
      self.new_image_tag = image_tag
      self.ecr_client = Aws::ECR::Client.new
      self.ecs_client = Aws::ECS::Client.new
    end

    private

    def task_family
      "#{app_name}-#{environment}"
    end

    def get_task_definition
      begin
        resp = ecs_client.describe_task_definition(
          {
            task_definition: task_family,
          })
      rescue StandardError => e
        puts "Failure in describe_task_definition for task family '#{task_family}': #{e}"
        raise "Failure in describe_task_definition for task family '#{task_family}"
      end

      resp.task_definition
    end

    def find_most_recent_tag(task_definition)
      repository_name = repository_name_from_task(task_definition)

      images = []
      begin
        resp = ecr_client.describe_images(
          {
            repository_name: repository_name
          }
        )
        images += resp[:image_details].to_a

        while resp.next_page? do
          resp = resp.next_page

          images += resp[:image_details].to_a
        end
      rescue StandardError => e
        puts "Error in describe_images for repo #{repository_name}: #{e}"
        raise "Error in describe_images for repo #{repository_name}"
      end

      raise "No images found for repo: #{repository_name}" if images.empty?

      # Get images, most recently pushed first
      images = images.sort_by(&:image_pushed_at).reverse

      image = images.first
      image_tags = image[:image_tags].dup
      image_tags.delete('latest')

      raise "Error. No specific tag found for image: #{JSON.pretty_generate(image.to_h)}" if image_tags.empty?

      most_recent_tag = image_tags.first

      if image_tags.length > 1
        puts("Warning. More than one specific tag found for image: #{JSON.pretty_generate(image.to_h)}. Using #{most_recent_tag}.")
      end

      most_recent_tag
    end

    def repository_name_from_task(task_definition)
      image = task_definition[:container_definitions].first[:image]
      m = /([^\/]+?)(?::[\S]+)?$/.match(image)

      raise "Unable to parse task definition image: #{image}" if m.nil?

      m[1]
    end

    def update_container_definitions(container_definitions)
      container_definition = container_definitions[0]
      update_container_environment(container_definition)
      container_definition[:image].sub!(/:[^\/\:]+$/, ":#{new_image_tag}")

      container_definitions
    end

    def update_container_environment(container_definition)
      environment = container_definition['environment']
      update_environment_setting(environment, name: 'APP_VERSION', value: new_image_tag)
      update_environment_setting(environment, name: 'DEPLOYED_AT', value: Time.now.strftime('%FT%T%:z'))
    end

    def update_environment_setting(environment, name:, value:)
      entry = environment.find { |e| e.name == name }
      if entry.nil?
        entry = Aws::ECS::Types::KeyValuePair.new(name: name, value: value)
        environment << entry
      else
        entry.value = value
      end
    end

    def update_task_definition(task_definition)
      container_definitions = task_definition[:container_definitions]

      raise "Error. Task definition has no container definitions." if container_definitions.empty?
      raise "Error. Task definition has more than one container definition." if container_definitions.length > 1

      updated_container_definitions = update_container_definitions(container_definitions)

      params = {
        container_definitions: updated_container_definitions,
        family: task_definition[:family],
        network_mode: task_definition[:network_mode],
        execution_role_arn: task_definition[:execution_role_arn],
        requires_compatibilities: task_definition[:requires_compatibilities],
        cpu: task_definition[:cpu],
        memory: task_definition[:memory]
      }

      begin
        resp = ecs_client.register_task_definition(params)
      rescue StandardError => e
        puts "Error in register_task_definition: #{e}"
        puts "Parameters: #{JSON.pretty_generate(params)}"
        raise "Error in register_task_definition"
      end

      # return the new arn
      resp[:task_definition][:task_definition_arn]
    end
  end
end
