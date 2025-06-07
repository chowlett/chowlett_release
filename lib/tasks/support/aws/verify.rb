require 'aws-sdk-sts'

module Aws
  # A module to verify AWS credentials and configuration.
  module Verify
    def self.verify
      client = Aws::STS::Client.new
      resp = client.get_caller_identity

      puts "Region: #{client.config&.region}"
      puts "Account: #{resp&.account}"
      puts "UserId: #{resp&.user_id}"
      puts "ARN: #{resp&.arn}"
      puts 'Inspect the above values for reasonableness.'
    rescue StandardError => e
      puts "Error verifying AWS credentials: #{e.message}"
    end
  end
end
