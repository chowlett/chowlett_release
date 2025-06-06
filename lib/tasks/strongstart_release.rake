namespace :strongstart_release do
  desc 'Prints a "Hello" message to the console. Verifies that the gem is functional.'
  task ping: :environment do
    require_relative './support/ping'

    Ping.ping
  rescue StandardError => e
    puts "Error pinging the gem: #{e.message}"
  end

  desc 'Build the release for the including app (SiTE SOURCES or GRFS)'
  task :build, [:no_tests] => :environment do |_, args|
    require_relative './support/build/executor'

    builder = Build::Executor.new(run_tests_please: args[:no_tests] != 'no_tests')
    builder.execute
  rescue StandardError => e
    puts "Error building the app: #{e.inspect}"
  end

  namespace :deploy do
    desc 'Deploy the staging release of the most recent build for the including app (SiTE SOURCES or GRFS)'
    task :staging, [:version_tag] => :environment do |_, args|
      require_relative './support/deploy/executor'

      deployer = Deploy::Executor.new(environment: :staging, version_tag: args[:version_tag])
      deployer.execute
    rescue StandardError => e
      puts "Error deploying the app: #{e.inspect}"
    end

    desc 'Deploy the production release of the most recent build for the including app (SiTE SOURCES or GRFS)'
    task :production, [:version_tag] => :environment do |_, args|
      require_relative './support/deploy/executor'

      deployer = Deploy::Executor.new(environment: :production, version_tag: args[:version_tag])
      deployer.execute
    rescue StandardError => e
      puts "Error deploying the app: #{e.inspect}"
    end
  end

  namespace :aws do
    desc 'Verify that AWS credentials are available for build and deploy. ' \
           'Returns information about the AWS account being used.'
    task verify: :environment do
      require_relative './support/aws/verify'

      Aws::Verify.verify
    rescue StandardError => e
      puts "Error verifying AWS credentials: #{e.inspect}"
    end
  end
end
