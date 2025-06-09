require_relative './support/error_chains'
require_relative './support/release_task_utils'

namespace :strongstart_release do
  desc 'Test multiple flags'
  task :flag_test, %i[arg1 arg2] => :environment do |_, args|
    flags = [args[:arg1], args[:arg2]].compact
    no_tests = flags.include?('--no-tests')
    dry_run  = flags.include?('--dry-run')
    unexpected_flags = flags - %w[--no-tests --dry-run]

    puts "Flags received: #{flags.join(', ')}"
    puts "Unexpected flags: #{unexpected_flags}" if unexpected_flags.any?
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
  task :build, %i[arg1 arg2] => :environment do |_, args|
    require_relative './support/build/executor'

    flags = [args[:arg1], args[:arg2]].compact
    unexpected_flags = flags - %w[--no-tests --dry-run]
    unless unexpected_flags.empty?
      puts "Unexpected arguments: #{unexpected_flags.join(', ')}"
      puts 'Valid arguments are: --no-tests, --dry-run'
      exit 1
    end

    no_tests = flags.include?('--no-tests')
    dry_run  = flags.include?('--dry-run')

    builder = Build::Executor.new(run_tests_please: !no_tests, dry_run_please: dry_run)
    builder.execute
  rescue StandardError => e
    ErrorChains.puts_error_chain e
  end

  namespace :deploy do
    desc 'Deploy the staging release of the most recent build for the including app (SiTE SOURCES or GRFS)'
    task :staging, [] => :environment do |_, task_args| # task_args is a Rake::TaskArguments with no keys
      require_relative './support/deploy/executor'
      
      puts "args: #{ReleaseTaskUtils.parse_deploy_args(task_args.to_a)}"

      raise 'Short-circuiting deploy task for testing purposes'

      deployer = Deploy::Executor.new(environment: :staging, version_tag: args[:version_tag])
      deployer.execute
    rescue StandardError => e
      ErrorChains.puts_error_chain e
    end

    desc 'Deploy the production release of the most recent build for the including app (SiTE SOURCES or GRFS)'
    task :production, [] => :environment do |_, task_args| # task_args is a Rake::TaskArguments with no keys
      require_relative './support/deploy/executor'

      puts "args: #{ReleaseTaskUtils.parse_deploy_args(task_args.to_a)}"

      raise 'Short-circuiting deploy task for testing purposes'

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
