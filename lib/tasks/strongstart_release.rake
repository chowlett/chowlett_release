namespace :strongstart_release do
  desc "Prints a \"Hello\" message to the console. Verifies that the gem is functional."
  task :ping => :environment do
    require_relative './support/ping'

    Ping.ping
  rescue StandardError => e
    puts "Error pinging the gem: #{e.message}"
  end

  namespace :build do
    desc "Build the staging release for the including app (SiTE SOURCES or GRFS)"
    task :staging => :environment do
      Rails.logger.info "Building whatever staging"
    rescue StandardError => e
      puts "Error building the app: #{e.message}"
    end

    desc "Build the production release for the including app (SiTE SOURCES or GRFS)"
    task :production => :environment do
      Rails.logger.info "Building whatever production"
    rescue StandardError => e
      puts "Error building the app: #{e.message}"
    end
  end

  namespace :deploy do
    desc "Deploy the staging release of the most recent build for the including app (SiTE SOURCES or GRFS)"
    task :staging => :environment do
      Rails.logger.info "Building whatever staging"
    rescue StandardError => e
      puts "Error deploying the app: #{e.message}"
    end

    desc "Deploy the production release of the most recent build for the including app (SiTE SOURCES or GRFS)"
    task :production => :environment do
      puts "Building whatever production"
    rescue StandardError => e
      puts "Error deploying the app: #{e.message}"
    end
  end

  namespace :aws do
    desc "Verify that AWS credentials are available for build and deploy. Returns information about the AWS account being used."
    task :verify => :environment do
      require_relative './support/aws/verify'

      Aws::Verify.verify
    rescue StandardError => e
      puts "Error verifying AWS credentials: #{e.message}"
    end
  end
end
