# require 'aws-sdk-ecs'
# require 'aws-sdk-ecr'

module Deploy
  # Register a new task definition for the ECS task family associated with the given app and environment.
  # The new task definition will have the same container definitions as the current one, except for
  # the image tag, and a couple of deployment-specific environment variables.
  # If no image tag is provided, the most recent tag from the associated ECR repository will be used. This is
  # the most common use case and typically immediately follows a build. The use case for providing an image tag
  # is "revert to a specific earlier version".
  class EcsTaskRegistrar # rubocop:disable Metrics/ClassLength
    attr_accessor :app_name, :environment, :new_image_tag, :dry_run, :ecr_client, :ecs_client

    def register
      task_definition = family_task_definition

      if new_image_tag.nil?
        self.new_image_tag = find_most_recent_tag(task_definition)

        puts "Using most recent image tag: #{new_image_tag}"
      else
        puts "Using provided image tag: #{new_image_tag}"
      end

      puts "Current task revision: #{task_definition[:revision]}"

      if dry_run
        puts 'Skipping registration of a new task definition because --dry-run.'
        return
      end

      new_task_arn = register_task_definition(task_definition)

      puts("Task #{new_task_arn} has been registered with image tag #{new_image_tag}")
    end

    def initialize(app_name:, environment:, image_tag: nil, dry_run: false)
      self.app_name = app_name
      self.environment = environment
      self.new_image_tag = image_tag
      self.dry_run = dry_run
      self.ecr_client = Aws::ECR::Client.new
      self.ecs_client = Aws::ECS::Client.new
    end

    private

    def task_family
      "#{app_name}-#{environment}"
    end

    # Return the latest active task definition for a task family. A "family" is defined by the app name and environment.
    # For example, sitesource-staging.
    def family_task_definition
      begin
        resp = ecs_client.describe_task_definition(
          {
            task_definition: task_family
          }
        )
      rescue StandardError => e
        puts "Failure in describe_task_definition for task family '#{task_family}': #{e}"
        raise "Failure in describe_task_definition for task family '#{task_family}"
      end

      resp.task_definition
    end

    # Find the most recent tag for the image in the ECR repository associated with the task definition.
    # "most recent" is defined as the most recently pushed image.
    def find_most_recent_tag(task_definition) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      repository_name = repository_name_from_task(task_definition)

      images = []
      begin
        resp = ecr_client.describe_images(
          {
            repository_name: repository_name
          }
        )
        images += resp[:image_details].to_a

        while resp.next_page? # FIXME: use a block with describe_images
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

      # There may be multiple tags for the same image. This can happen if an app is built two times in succession with
      # no intervening code change. In this case, we will see one image with two version number tags, e.g. 25.1.9 and
      # 25.1.10. We resolve this by using the tag most recently pushed. In our example, this would be 25.1.10.
      if image_tags.length > 1
        puts("Warning. More than one specific tag found for image: #{JSON.pretty_generate(image.to_h)}. " \
               "Using #{most_recent_tag}.")
      end

      most_recent_tag
    end

    def repository_name_from_task(task_definition)
      image = task_definition[:container_definitions].first[:image]
      # Match the text after the last / and exclude the tag.
      # Example - 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:latest, the match group will be my-repo.
      m = %r{([^/]+?)(?::\S+)?$}.match(image)

      raise "Unable to parse task definition image: #{image}" if m.nil?

      m[1]
    end

    # Update the container definitions in the task definition with the new image tag.
    # BTW, there is only one container definition in our cases.
    def update_container_definitions(container_definitions)
      container_definition = container_definitions[0]
      update_container_environment(container_definition)
      container_definition[:image].sub!(%r{:[^/:]+$}, ":#{new_image_tag}")

      container_definitions
    end

    # Update the deployment-specific environment variables in the container definition.
    def update_container_environment(container_definition)
      environment = container_definition['environment']
      update_environment_setting(environment, name: 'APP_VERSION', value: new_image_tag)
      update_environment_setting(environment, name: 'DEPLOYED_AT', value: Time.now.strftime('%FT%T%:z'))
    end

    # A helper method that updates an environment variable in the container definition.
    def update_environment_setting(environment, name:, value:)
      entry = environment.find { |e| e.name == name }
      if entry.nil?
        entry = Aws::ECS::Types::KeyValuePair.new(name: name, value: value)
        environment << entry
      else
        entry.value = value
      end
    end

    # Register the new task definition. It will be the same as the current one, except for the image tag and
    # a couple of deployment-specific container environment variables.
    def register_task_definition(task_definition) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      container_definitions = task_definition[:container_definitions]

      raise 'Error. Task definition has no container definitions.' if container_definitions.empty?
      raise 'Error. Task definition has more than one container definition.' if container_definitions.length > 1

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
        raise 'Error in register_task_definition'
      end

      # return the new arn
      resp[:task_definition][:task_definition_arn]
    end
  end
end
