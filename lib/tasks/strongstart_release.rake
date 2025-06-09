require_relative './support/error_chains'
require_relative './support/release_task_utils'

namespace :strongstart_release do
  desc 'Prints a "Hello" message to the console. Verifies that the gem is functional.'
  task ping: :environment do
    require_relative './support/ping'

    Ping.ping
  rescue StandardError => e
    ErrorChains.puts_error_chain e
  end

  desc 'Build the release for the including app (SiTE SOURCES or GRFS).'\
         ' Optional arguments: --no-tests, --dry-run'
  task :build, [] => :environment do |_, args|
    require_relative './support/build/executor'

    parsed = ReleaseTaskUtils.parse_deploy_args task_args.to_a
    run_tests_please = !parsed[:no_tests]
    dry_run_please = parsed[:dry_run]

    builder = Build::Executor.new(run_tests_please:, dry_run_please:)
    builder.execute
  rescue StandardError => e
    ErrorChains.puts_error_chain e
  end

  namespace :deploy do
    desc 'Deploy the staging release of the most recent build for the including app (SiTE SOURCES or GRFS).'\
          ' Optional arguments: version_tag, --dry-run'
    task :staging, [] => :environment do |_, task_args| # task_args is a Rake::TaskArguments with no keys
      require_relative './support/deploy/executor'
      
      parsed = ReleaseTaskUtils.parse_deploy_args task_args.to_a

      deployer = Deploy::Executor.new(environment: :staging, version_tag: parsed[:tag], dry_run: parsed[:dry_run])
      deployer.execute
    rescue StandardError => e
      ErrorChains.puts_error_chain e
    end

    desc 'Deploy the production release of the most recent build for the including app (SiTE SOURCES or GRFS)'
    task :production, [] => :environment do |_, task_args| # task_args is a Rake::TaskArguments with no keys
      require_relative './support/deploy/executor'

      parsed = ReleaseTaskUtils.parse_deploy_args task_args.to_a

      deployer = Deploy::Executor.new(environment: :production, version_tag: parsed[:tag], dry_run: parsed[:dry_run])
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
