require_relative './support/error_chains'

namespace :strongstart_release do
  desc 'Test multiple flags'
  task :flag_test, %i[arg1 arg2] => :environment do |_, args|
    flags = [args[:arg1], args[:arg2]].compact
    no_tests = flags.include?('--no-tests')
    dry_run  = flags.include?('--dry-run')

    puts "Flags received: #{flags.join(', ')}"
    puts "No tests: #{no_tests}"
    puts "Dry run: #{dry_run}"
  end

  desc 'Prints a "Hello" message to the console. Verifies that the gem is functional.'
  task ping: :environment do
    require_relative './support/ping'

    Ping.ping
  rescue StandardError => e
    ErrorChains.puts_error_chain e
  end

  desc 'Build the release for the including app (SiTE SOURCES or GRFS)'
  task :build, [:no_tests] => :environment do |_, args|
    require_relative './support/build/executor'

    builder = Build::Executor.new(run_tests_please: args[:no_tests] != 'no_tests')
    builder.execute
  rescue StandardError => e
    ErrorChains.puts_error_chain e
  end

  namespace :deploy do
    desc 'Deploy the staging release of the most recent build for the including app (SiTE SOURCES or GRFS)'
    task :staging, [:version_tag] => :environment do |_, args|
      require_relative './support/deploy/executor'

      deployer = Deploy::Executor.new(environment: :staging, version_tag: args[:version_tag])
      deployer.execute
    rescue StandardError => e
      ErrorChains.puts_error_chain e
    end

    desc 'Deploy the production release of the most recent build for the including app (SiTE SOURCES or GRFS)'
    task :production, [:version_tag] => :environment do |_, args|
      require_relative './support/deploy/executor'

      deployer = Deploy::Executor.new(environment: :production, version_tag: args[:version_tag])
      deployer.execute
    rescue StandardError => e
      ErrorChains.puts_error_chain e
    end
  end

  namespace :aws do
    desc 'Verify that AWS credentials are available for build and deploy. ' \
           'Returns information about the AWS account being used.'
    task verify: :environment do
      require_relative './support/aws/verify'

      Aws::Verify.verify
    rescue StandardError => e
      ErrorChains.puts_error_chain e
    end
  end
end
