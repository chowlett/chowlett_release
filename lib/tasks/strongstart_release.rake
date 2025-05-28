namespace :strongstart_release do
  desc "Log Hello World"
  task :ping => :environment do
    Rails.logger.info "Hello World!"
  end

  namespace :build do
    desc "Build the staging release for the including app (SiTE SOURCES or GRFS)"
    task :staging => :environment do
      Rails.logger.info "Building whatever staging"
    end
    desc "Build the production release for the including app (SiTE SOURCES or GRFS)"
    task :production => :environment do
      Rails.logger.info "Building whatever production"
    end
  end

  namespace :deploy do
    desc "Deploy the staging release of the most recent build for the including app (SiTE SOURCES or GRFS)"
    task :staging => :environment do
      Rails.logger.info "Building whatever staging"
    end
    desc "Deploy the production release of the most recent build for the including app (SiTE SOURCES or GRFS)"
    task :production => :environment do
      Rails.logger.info "Building whatever production"
    end
  end

  namespace :aws do
    desc "Verify that AWS credentials are available for build and deploy"
    task :verify_auth => :environment do
      Rails.logger.info "Hello World from AWS!"
    end
  end
end
